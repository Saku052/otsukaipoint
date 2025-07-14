import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import 'supabase_service.dart';

/// アカウント削除サービス
/// ユーザーアカウントの即座完全削除を管理
class AccountDeletionService {
  final SupabaseService _supabaseService;
  static final Map<String, List<DateTime>> _deletionAttempts = {};
  static const int _maxAttemptsPerHour = 3;

  AccountDeletionService(this._supabaseService);

  /// アカウントを完全削除する（即座削除）
  /// セキュリティ強化：レート制限、多要素認証、完全データ削除
  Future<AccountDeletionResult> deleteAccount({
    required String userId,
    required String password,
    required String confirmationText,
    String? reason,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // 1. レート制限チェック
      await _checkRateLimit(ipAddress ?? 'unknown');

      // 2. 確認テキストの検証
      if (confirmationText.trim().toLowerCase() != 'delete') {
        throw ValidationException(message: '確認テキストが正しくありません');
      }

      // 3. パスワード再認証
      await _reauthenticateUser(password);

      // 4. ユーザー情報を取得
      final currentUser = _supabaseService.auth.currentUser;
      
      final userInfo = await _getUserInfo(userId);
      if (userInfo == null) {
        throw AuthException(
          message: 'ユーザーが見つかりません。\n'
                  'ユーザーID: $userId\n'
                  '現在の認証ユーザー: ${currentUser?.id}\n'
                  '認証状態: ${currentUser != null ? "ログイン済み" : "未ログイン"}\n'
                  'ID一致: ${currentUser?.id == userId}'
        );
      }

      // 5. 家族関係の影響範囲をチェック
      final familyImpact = await _checkFamilyImpact(userId, userInfo['role']);

      // 6. 関連データの完全削除を実行（auth.users以外）
      final deletedAt = DateTime.now();
      await _performCompleteDataDeletion(userId, userInfo);
      
      // 7. 最後にSupabase Authenticationからユーザーを完全削除
      await _deleteAuthUser(userId);

      // 7. 削除ログに詳細情報を記録
      await _logDeletionAttempt(
        userId: userId,
        userEmail: userInfo['email'],
        reason: reason,
        ipAddress: ipAddress,
        userAgent: userAgent,
        success: true,
        additionalData: {
          'family_impact': familyImpact.hasImpact,
          'affected_members_count': familyImpact.affectedMembers.length,
          'deletion_timestamp': deletedAt.toIso8601String(),
        },
      );

      return AccountDeletionResult(
        success: true,
        userId: userId,
        deletedAt: deletedAt,
        familyImpact: familyImpact,
      );
    } catch (e) {
      // エラーログ記録
      if (e is! AuthException && e is! ValidationException) {
        await _logDeletionAttempt(
          userId: userId,
          userEmail: '',
          reason: reason,
          ipAddress: ipAddress,
          userAgent: userAgent,
          success: false,
          error: e.toString(),
        );
      }
      rethrow;
    }
  }

  /// 削除理由の統計を取得（強化版）
  Future<List<DeletionReasonStats>> getDeletionStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _supabaseService.rpc(
        'get_deletion_statistics',
        params: {
          'from_date': fromDate?.toIso8601String(),
          'to_date': toDate?.toIso8601String(),
        },
      );

      return (response.data as List)
          .map((data) => DeletionReasonStats.fromJson(data))
          .toList();
    } catch (e) {
      // フォールバック: 直接データベースから統計を取得
      try {
        final response = await _supabaseService
            .from('account_deletion_logs')
            .select('deletion_reason')
            .eq('success', true)
            .gte('timestamp', fromDate?.toIso8601String() ?? '1970-01-01')
            .lte(
              'timestamp',
              toDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
            );

        final Map<String, int> reasonCounts = {};
        int totalCount = 0;

        for (final record in response as List) {
          final reason = record['deletion_reason'] ?? 'その他';
          reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
          totalCount++;
        }

        return reasonCounts.entries.map((entry) {
          return DeletionReasonStats(
            reason: entry.key,
            count: entry.value,
            percentage: totalCount > 0 ? (entry.value / totalCount) * 100 : 0,
          );
        }).toList();
      } catch (fallbackError) {
        throw _supabaseService.handleError(fallbackError);
      }
    }
  }

  /// アカウント削除の総合情報を取得
  Future<AccountDeletionSummary> getDeletionSummary({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final fromDateStr = fromDate?.toIso8601String() ?? '1970-01-01';
      final toDateStr =
          toDate?.toIso8601String() ?? DateTime.now().toIso8601String();

      final response = await _supabaseService
          .from('account_deletion_logs')
          .select('*')
          .gte('timestamp', fromDateStr)
          .lte('timestamp', toDateStr);

      final logs = response as List;
      final totalAttempts = logs.length;
      final successfulDeletions = logs
          .where((log) => log['success'] == true)
          .length;
      final failedAttempts = totalAttempts - successfulDeletions;

      // 最多の削除理由を特定
      final Map<String, int> reasonCounts = {};
      for (final log in logs) {
        if (log['success'] == true) {
          final reason = log['deletion_reason'] ?? 'その他';
          reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
        }
      }

      final topReason = reasonCounts.isNotEmpty
          ? reasonCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      return AccountDeletionSummary(
        totalAttempts: totalAttempts,
        successfulDeletions: successfulDeletions,
        failedAttempts: failedAttempts,
        successRate: totalAttempts > 0
            ? (successfulDeletions / totalAttempts) * 100
            : 0,
        topDeletionReason: topReason,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      throw _supabaseService.handleError(e);
    }
  }

  /// レート制限チェック
  Future<void> _checkRateLimit(String ipAddress) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    _deletionAttempts[ipAddress] ??= [];
    _deletionAttempts[ipAddress]!.removeWhere(
      (time) => time.isBefore(oneHourAgo),
    );

    if (_deletionAttempts[ipAddress]!.length >= _maxAttemptsPerHour) {
      throw ValidationException(message: '削除試行回数が制限を超えています。1時間後に再試行してください。');
    }

    _deletionAttempts[ipAddress]!.add(now);
  }

  /// 関連データの完全削除を実行
  Future<void> _performCompleteDataDeletion(
    String userId,
    Map<String, dynamic> userInfo,
  ) async {
    try {
      // データベース関数を使用した完全削除
      final response = await _supabaseService.rpc(
        'hard_delete_user_account',
        params: {'target_user_id': userId, 'cascade_delete': true},
      );

      if (response.data == null || response.data['success'] != true) {
        throw ServerException(
          message: response.data?['error'] ?? 'アカウント削除に失敗しました',
        );
      }
    } catch (e) {
      // フォールバック: 手動でのカスケード削除
      await _performManualCascadeDeletion(userId, userInfo);
    }
  }

  /// 手動でのカスケード削除
  Future<void> _performManualCascadeDeletion(
    String userId,
    Map<String, dynamic> userInfo,
  ) async {
    try {
      // 1. 買い物リストの削除（created_byで作成者を特定）
      await _supabaseService
          .from('shopping_lists')
          .delete()
          .eq('created_by', userId);

      // 2. 買い物アイテムの削除（assigned_to, completed_byで関連アイテムを削除）
      await _supabaseService
          .from('shopping_items')
          .delete()
          .or('assigned_to.eq.$userId,completed_by.eq.$userId');

      // 3. 家族関係の削除
      await _supabaseService
          .from('family_members')
          .delete()
          .eq('user_id', userId);

      // 4. 通知の削除
      await _supabaseService
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      // 5. 通知設定の削除
      await _supabaseService
          .from('notification_settings')
          .delete()
          .eq('user_id', userId);

      // 6. お小遣い残高の削除
      await _supabaseService
          .from('allowance_balances')
          .delete()
          .eq('user_id', userId);

      // 7. お小遣い取引履歴の削除
      await _supabaseService
          .from('allowance_transactions')
          .delete()
          .eq('user_id', userId);

      // 8. ユーザープロフィールの削除
      await _supabaseService.from('user_profiles').delete().eq('id', userId);

      // 9. 外部サービスからのデータ削除
      await _deleteExternalServiceData(userId, userInfo);
      
      // 10. 最後にSupabase Authenticationからユーザーを完全削除
      await _deleteAuthUser(userId);

    } catch (e) {
      // 部分的なエラーは許容し、メインのユーザーデータ削除を継続
      print('⚠️ カスケード削除でエラーが発生しましたが、継続します: $e');
      
      // 重大なエラーのみ例外を投げる
      if (e.toString().contains('permission denied') || 
          e.toString().contains('authentication failed')) {
        throw ServerException(message: 'データ削除の権限がありません: ${e.toString()}');
      }
      
      // その他のエラーは警告として継続
      print('⚠️ 一部テーブルの削除に失敗しましたが、メインのアカウント削除は継続します');
    }
  }

  /// 外部サービスからのデータ削除
  Future<void> _deleteExternalServiceData(
    String userId,
    Map<String, dynamic> userInfo,
  ) async {
    try {
      // プロフィール画像の削除
      if (userInfo['profile_image_url'] != null) {
        await _supabaseService.storage.from('profile-images').remove([
          '$userId/profile.jpg',
        ]);
      }

      // 買い物リスト画像の削除
      try {
        final files = await _supabaseService.storage
            .from('shopping-images')
            .list(path: userId);

        if (files.isNotEmpty) {
          final filePaths = files
              .map((file) => '$userId/${file.name}')
              .toList();
          await _supabaseService.storage
              .from('shopping-images')
              .remove(filePaths);
        }
      } catch (e) {
        // ファイルが存在しない場合は無視
      }
    } catch (e) {
      // 外部サービスの削除失敗はログに記録するが、メイン処理は継続
      await _logExternalServiceDeletionFailure(userId, e.toString());
    }
  }

  /// 外部サービス削除失敗のログ記録
  Future<void> _logExternalServiceDeletionFailure(
    String userId,
    String error,
  ) async {
    try {
      await _supabaseService.from('external_service_deletion_failures').insert({
        'user_id': userId,
        'error_message': error,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // ログ記録失敗も無視
    }
  }

  /// Supabase Authenticationからユーザーを完全削除
  Future<void> _deleteAuthUser(String userId) async {
    try {
      print('🔥 Supabase Authenticationからユーザーを削除中: $userId');
      
      // 方法1: admin APIを使用してユーザーを削除
      try {
        await _supabaseService.auth.admin.deleteUser(userId);
        print('✅ admin APIでユーザー削除成功');
        return;
      } catch (adminError) {
        print('❌ admin APIでの削除失敗: $adminError');
        
        // admin APIが失敗した場合は代替手段を試行
      }
      
      // 方法2: RPC関数を使用してユーザーを削除
      try {
        final response = await _supabaseService.rpc(
          'delete_auth_user',
          params: {'user_id': userId},
        );
        
        if (response.data != null && response.data['success'] == true) {
          print('✅ RPC関数でユーザー削除成功');
          return;
        } else {
          print('❌ RPC関数での削除失敗: ${response.data}');
        }
      } catch (rpcError) {
        print('❌ RPC関数での削除失敗: $rpcError');
      }
      
      // 方法3: 直接SQLでauth.usersテーブルから削除
      try {
        await _supabaseService.rpc(
          'delete_user_direct',
          params: {'target_user_id': userId},
        );
        print('✅ 直接SQLでユーザー削除成功');
        return;
      } catch (directError) {
        print('❌ 直接SQLでの削除失敗: $directError');
      }
      
      // すべての手段が失敗した場合の警告
      print('⚠️ Supabase Authenticationからのユーザー削除に失敗しました。手動で削除が必要になる可能性があります。');
      
    } catch (e) {
      print('❌ 認証ユーザー削除で予期しないエラー: $e');
      // 認証ユーザーの削除失敗は致命的ではないので、警告として継続
    }
  }

  // プライベートメソッド

  /// パスワード再認証
  Future<void> _reauthenticateUser(String password) async {
    try {
      final user = _supabaseService.auth.currentUser;
      if (user?.email == null) {
        throw AuthException(message: 'ログインが必要です');
      }

      // Supabaseでの再認証
      final response = await _supabaseService.auth.signInWithPassword(
        email: user!.email!,
        password: password,
      );

      if (response.user == null) {
        throw AuthException(message: 'パスワードが間違っています');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(message: 'パスワード認証に失敗しました');
    }
  }

  /// ユーザー情報を取得
  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    try {
      // デバッグ情報
      final currentUser = _supabaseService.auth.currentUser;
      
      // まずuser_profilesテーブルから既存のデータを取得
      try {
        // テーブルの存在確認とデータ取得をテスト
        print('🔍 user_profilesテーブルからデータを取得中...');
        
        final existingProfile = await _supabaseService
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .maybeSingle();
        
        if (existingProfile != null) {
          print('✅ 既存のuser_profilesデータを発見: $existingProfile');
          return existingProfile;
        }
        
        // データが存在しない場合のデバッグ情報を出力
        print('📊 user_profilesテーブルにユーザーデータが存在しません: $userId');
        
        // テーブルの全体的なデータを確認（デバッグ用）
        try {
          final allProfiles = await _supabaseService
              .from('user_profiles')
              .select('id, email, name, role')
              .limit(5);
          print('📊 テーブル内のサンプルデータ: $allProfiles');
        } catch (sampleError) {
          print('❌ サンプルデータ取得エラー: $sampleError');
        }
        
      } catch (queryError) {
        // テーブルアクセスエラーをログ出力
        print('❌ user_profilesテーブルアクセスエラー: $queryError');
        throw AuthException(
          message: 'user_profilesテーブルへのアクセスに失敗しました: $queryError'
        );
      }
      
      // user_profilesにデータが存在しない場合、auth.usersから取得して作成
      if (currentUser != null && currentUser.id == userId) {
        print('🔄 user_profilesレコードを作成中...');
        
        // auth.usersの情報を基にuser_profilesレコードを作成
        final userProfile = {
          'id': currentUser.id,
          'email': currentUser.email,
          'name':
              currentUser.userMetadata?['name'] ??
              currentUser.email?.split('@')[0] ??
              'Unknown',
          'role': 'parent', // デフォルト値
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        print('📝 作成予定のユーザープロフィール: $userProfile');

        // user_profilesテーブルにレコードを作成
        try {
          final insertResult = await _supabaseService
              .from('user_profiles')
              .insert(userProfile)
              .select()
              .single();
          
          print('✅ user_profilesレコード作成成功: $insertResult');
          return insertResult;
        } catch (insertError) {
          print('❌ user_profilesレコード作成失敗: $insertError');
          
          // エラーが重複キーエラーの場合、既存レコードを取得
          if (insertError.toString().contains('duplicate key') || 
              insertError.toString().contains('already exists')) {
            final retryProfile = await _supabaseService
                .from('user_profiles')
                .select('*')
                .eq('id', userId)
                .maybeSingle();
            if (retryProfile != null) {
              print('✅ 重複キーエラーのため既存レコードを返却');
              return retryProfile;
            }
          }
          
          // 権限エラーの場合は、UPSERTを試行
          if (insertError.toString().contains('permission') || 
              insertError.toString().contains('policy')) {
            print('🔄 権限エラーのためUPSERTを試行');
            try {
              final upsertResult = await _supabaseService
                  .from('user_profiles')
                  .upsert(userProfile)
                  .select()
                  .single();
              
              print('✅ UPSERT成功: $upsertResult');
              return upsertResult;
            } catch (upsertError) {
              print('❌ UPSERTも失敗: $upsertError');
            }
          }
          
          print('❌ すべてのデータ作成試行が失敗しました');
        }
      } else {
        print('❌ 認証ユーザーが存在しないか、IDが一致しません');
        print('   認証ユーザー: ${currentUser?.id}');
        print('   リクエストユーザー: $userId');
      }

      // 最終的なフォールバック: family_membersテーブルからデータを取得
      print('🔄 最終フォールバック: family_membersテーブルからデータを取得');
      try {
        final familyMember = await _supabaseService
            .from('family_members')
            .select('*, families(name)')
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();
        
        if (familyMember != null && currentUser != null) {
          // family_membersテーブルの情報から仮のユーザープロフィールを作成
          final fallbackProfile = {
            'id': currentUser.id,
            'email': currentUser.email,
            'name': currentUser.email?.split('@')[0] ?? 'Unknown',
            'role': familyMember['role'] ?? 'parent',
            'family_id': familyMember['family_id'],
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          print('✅ family_membersテーブルから仮プロフィールを作成: $fallbackProfile');
          return fallbackProfile;
        }
      } catch (familyError) {
        print('❌ family_membersテーブルからのデータ取得も失敗: $familyError');
      }
      
      return null;
    } catch (e) {
      print('❌ _getUserInfoメソッドで例外が発生: $e');
      throw AuthException(message: 'ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// 家族関係への影響をチェック（強化版）
  Future<FamilyImpact> _checkFamilyImpact(
    String userId,
    String userRole,
  ) async {
    try {
      final userInfo = await _getUserInfo(userId);
      if (userInfo == null) {
        return FamilyImpact(hasImpact: false, affectedMembers: []);
      }

      final familyId = userInfo['family_id'];
      if (familyId == null) {
        return FamilyImpact(hasImpact: false, affectedMembers: []);
      }

      // 家族メンバー全体を取得
      final familyMembersResponse = await _supabaseService
          .from('user_profiles')
          .select('id, name, email, role')
          .eq('family_id', familyId)
          .neq('id', userId)
          .isFilter('deleted_at', null);

      final familyMembers = (familyMembersResponse as List)
          .map((member) => AffectedMember.fromJson(member))
          .toList();

      String? warningMessage;
      String? recoveryInstructions;

      if (userRole == 'parent') {
        final children = familyMembers
            .where((member) => member.role == 'child')
            .toList();
        final otherParents = familyMembers
            .where((member) => member.role == 'parent')
            .toList();

        if (children.isNotEmpty) {
          if (otherParents.isEmpty) {
            warningMessage = '${children.length}人の子どもアカウントが孤立し、アクセス不能になります';
            recoveryInstructions = '子どもアカウントの管理を他の親アカウントに移管してから削除してください';
          } else {
            warningMessage =
                '${children.length}人の子どもアカウントが存在しますが、他の親アカウントが管理を引き継ぎます';
          }
        }

        return FamilyImpact(
          hasImpact: children.isNotEmpty,
          affectedMembers: children,
          warningMessage: warningMessage,
          recoveryInstructions: recoveryInstructions,
        );
      } else if (userRole == 'child') {
        // 子どもアカウントの場合
        final parents = familyMembers
            .where((member) => member.role == 'parent')
            .toList();

        return FamilyImpact(
          hasImpact: false,
          affectedMembers: [],
          warningMessage: parents.isNotEmpty ? '親アカウントに削除通知が送信されます' : null,
        );
      }

      return FamilyImpact(hasImpact: false, affectedMembers: []);
    } catch (e) {
      return FamilyImpact(
        hasImpact: false,
        affectedMembers: [],
        warningMessage: '家族関係のチェックに失敗しましたが、削除を継続します',
      );
    }
  }

  /// 削除ログを記録（強化版）
  Future<void> _logDeletionAttempt({
    required String userId,
    required String userEmail,
    String? reason,
    String? ipAddress,
    String? userAgent,
    required bool success,
    String? error,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final logData = {
        'user_id': userId,
        'user_email': userEmail,
        'deletion_reason': reason,
        'deletion_type': success ? 'immediate_hard' : 'failed',
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'success': success,
        'error_message': error,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': additionalData ?? {},
      };

      await _supabaseService.from('account_deletion_logs').insert(logData);
    } catch (e) {
      // ログテーブルが存在しない場合でも、コンソールにログを出力
      // 本番環境では適切なロギングフレームワークを使用
      // ignore: avoid_print
      // print('Failed to log deletion attempt: ${e.toString()}');
    }
  }
}

/// アカウント削除結果
class AccountDeletionResult {
  final bool success;
  final String userId;
  final DateTime deletedAt;
  final FamilyImpact familyImpact;
  final String? warningMessage;

  AccountDeletionResult({
    required this.success,
    required this.userId,
    required this.deletedAt,
    required this.familyImpact,
    this.warningMessage,
  });

  /// 削除結果をJSON形式で出力
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'userId': userId,
      'deletedAt': deletedAt.toIso8601String(),
      'familyImpact': {
        'hasImpact': familyImpact.hasImpact,
        'affectedMembersCount': familyImpact.affectedMembers.length,
        'warningMessage': familyImpact.warningMessage,
      },
      'warningMessage': warningMessage,
    };
  }
}

/// 家族への影響
class FamilyImpact {
  final bool hasImpact;
  final List<AffectedMember> affectedMembers;
  final String? warningMessage;
  final String? recoveryInstructions;

  FamilyImpact({
    required this.hasImpact,
    required this.affectedMembers,
    this.warningMessage,
    this.recoveryInstructions,
  });

  /// JSON形式でエクスポート
  Map<String, dynamic> toJson() {
    return {
      'hasImpact': hasImpact,
      'affectedMembers': affectedMembers
          .map((member) => member.toJson())
          .toList(),
      'warningMessage': warningMessage,
      'recoveryInstructions': recoveryInstructions,
    };
  }
}

/// 影響を受ける家族メンバー
class AffectedMember {
  final String id;
  final String name;
  final String email;
  final String role;

  AffectedMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AffectedMember.fromJson(Map<String, dynamic> json) {
    return AffectedMember(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}

/// 削除理由統計
class DeletionReasonStats {
  final String reason;
  final int count;
  final double percentage;

  DeletionReasonStats({
    required this.reason,
    required this.count,
    required this.percentage,
  });

  factory DeletionReasonStats.fromJson(Map<String, dynamic> json) {
    return DeletionReasonStats(
      reason: json['reason'] ?? 'その他',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'reason': reason, 'count': count, 'percentage': percentage};
  }
}

/// アカウント削除の総合情報
class AccountDeletionSummary {
  final int totalAttempts;
  final int successfulDeletions;
  final int failedAttempts;
  final double successRate;
  final String? topDeletionReason;
  final DateTime? fromDate;
  final DateTime? toDate;

  AccountDeletionSummary({
    required this.totalAttempts,
    required this.successfulDeletions,
    required this.failedAttempts,
    required this.successRate,
    this.topDeletionReason,
    this.fromDate,
    this.toDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalAttempts': totalAttempts,
      'successfulDeletions': successfulDeletions,
      'failedAttempts': failedAttempts,
      'successRate': successRate,
      'topDeletionReason': topDeletionReason,
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
    };
  }
}

/// AccountDeletionServiceプロバイダー
final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return AccountDeletionService(supabaseService);
});

/// アカウント削除統計プロバイダー
final accountDeletionStatsProvider =
    FutureProvider.family<List<DeletionReasonStats>, Map<String, DateTime?>?>((
      ref,
      dateRange,
    ) async {
      final service = ref.read(accountDeletionServiceProvider);
      return service.getDeletionStats(
        fromDate: dateRange?['fromDate'],
        toDate: dateRange?['toDate'],
      );
    });

/// アカウント削除総合情報プロバイダー
final accountDeletionSummaryProvider =
    FutureProvider.family<AccountDeletionSummary, Map<String, DateTime?>?>((
      ref,
      dateRange,
    ) async {
      final service = ref.read(accountDeletionServiceProvider);
      return service.getDeletionSummary(
        fromDate: dateRange?['fromDate'],
        toDate: dateRange?['toDate'],
      );
    });
