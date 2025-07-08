import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family.dart' as family_entities;
import '../services/supabase_service.dart';
import '../../core/errors/exceptions.dart';
import 'dart:math';

/// 家族管理リポジトリ
class FamilyRepository {
  final SupabaseService _supabaseService;

  FamilyRepository(this._supabaseService);

  /// 新しい家族を作成
  Future<family_entities.Family> createFamily(String name, String createdBy) async {
    try {
      final now = DateTime.now();
      final inviteCode = _generateInviteCode();
      
      final familyData = {
        'name': name,
        'invite_code': inviteCode,
        'created_by': createdBy,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('families')
          .insert(familyData)
          .select()
          .single();

      final family = family_entities.Family.fromMap(response);

      // 作成者を家族メンバーとして追加
      await addFamilyMember(
        familyId: family.id,
        userId: createdBy,
        role: 'parent',
      );

      return family;
    } catch (e) {
      throw ServerException(message: '家族の作成に失敗しました: $e');
    }
  }

  /// 招待コードで家族を検索
  Future<family_entities.Family?> findFamilyByInviteCode(String inviteCode) async {
    try {
      final response = await _supabaseService.client
          .from('families')
          .select()
          .eq('invite_code', inviteCode)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      
      return family_entities.Family.fromMap(response);
    } catch (e) {
      throw ServerException(message: '家族の検索に失敗しました: $e');
    }
  }

  /// 家族情報を取得
  Future<family_entities.Family?> getFamily(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('families')
          .select()
          .eq('id', familyId)
          .maybeSingle();

      if (response == null) return null;
      
      return family_entities.Family.fromMap(response);
    } catch (e) {
      throw ServerException(message: '家族情報の取得に失敗しました: $e');
    }
  }

  /// 家族に参加
  Future<family_entities.FamilyMember> joinFamily({
    required String familyId,
    required String userId,
    required String role,
  }) async {
    try {
      // 既にメンバーでないかチェック
      final existingMember = await getFamilyMember(familyId, userId);
      if (existingMember != null && existingMember.isActive) {
        throw ServerException(message: '既にこの家族のメンバーです');
      }

      return await addFamilyMember(
        familyId: familyId,
        userId: userId,
        role: role,
      );
    } catch (e) {
      throw ServerException(message: '家族への参加に失敗しました: $e');
    }
  }

  /// 家族メンバーを追加
  Future<family_entities.FamilyMember> addFamilyMember({
    required String familyId,
    required String userId,
    required String role,
    String? invitedBy,
  }) async {
    try {
      final now = DateTime.now();
      final memberData = {
        'family_id': familyId,
        'user_id': userId,
        'role': role,
        'is_active': true,
        'invited_by': invitedBy,
        'joined_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('family_members')
          .insert(memberData)
          .select()
          .single();

      return family_entities.FamilyMember.fromMap(response);
    } catch (e) {
      throw ServerException(message: '家族メンバーの追加に失敗しました: $e');
    }
  }

  /// 家族メンバーを取得
  Future<family_entities.FamilyMember?> getFamilyMember(String familyId, String userId) async {
    try {
      final response = await _supabaseService.client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      
      return family_entities.FamilyMember.fromMap(response);
    } catch (e) {
      throw ServerException(message: '家族メンバー情報の取得に失敗しました: $e');
    }
  }

  /// 家族の全メンバーを取得
  Future<List<family_entities.FamilyMember>> getFamilyMembers(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('family_members')
          .select('''
            *,
            user:users(
              id,
              name,
              email,
              avatar_url,
              role
            )
          ''')
          .eq('family_id', familyId)
          .eq('is_active', true)
          .order('joined_at');

      return response.map<family_entities.FamilyMember>((data) {
        return family_entities.FamilyMember.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: '家族メンバー一覧の取得に失敗しました: $e');
    }
  }

  /// 家族の子どもメンバーを取得
  Future<List<family_entities.FamilyMember>> getFamilyChildren(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('family_members')
          .select('''
            *,
            user:users(
              id,
              name,
              email,
              avatar_url,
              role
            )
          ''')
          .eq('family_id', familyId)
          .eq('role', 'child')
          .eq('is_active', true)
          .order('joined_at');

      return response.map<family_entities.FamilyMember>((data) {
        return family_entities.FamilyMember.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: '子どもメンバー一覧の取得に失敗しました: $e');
    }
  }

  /// 家族から脱退
  Future<void> leaveFamilyMember(String familyId, String userId) async {
    try {
      await _supabaseService.client
          .from('family_members')
          .update({
            'is_active': false,
            'left_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('family_id', familyId)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerException(message: '家族からの脱退に失敗しました: $e');
    }
  }

  /// 新しい招待コードを生成
  Future<family_entities.Family> generateNewInviteCode(String familyId) async {
    try {
      final newInviteCode = _generateInviteCode();
      
      final response = await _supabaseService.client
          .from('families')
          .update({
            'invite_code': newInviteCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId)
          .select()
          .single();

      return family_entities.Family.fromMap(response);
    } catch (e) {
      throw ServerException(message: '招待コードの更新に失敗しました: $e');
    }
  }

  /// 家族名を更新
  Future<family_entities.Family> updateFamilyName(String familyId, String newName) async {
    try {
      final response = await _supabaseService.client
          .from('families')
          .update({
            'name': newName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId)
          .select()
          .single();

      return family_entities.Family.fromMap(response);
    } catch (e) {
      throw ServerException(message: '家族名の更新に失敗しました: $e');
    }
  }

  /// ユーザーが所属する家族を取得
  Future<family_entities.Family?> getUserFamily(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('family_members')
          .select('''
            family:families(*)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null || response['family'] == null) return null;
      
      return family_entities.Family.fromMap(response['family']);
    } catch (e) {
      throw ServerException(message: 'ユーザーの家族情報取得に失敗しました: $e');
    }
  }

  /// 家族統計を取得
  Future<Map<String, int>> getFamilyStats(String familyId) async {
    try {
      final members = await getFamilyMembers(familyId);
      final children = members.where((m) => m.role == 'child').length;
      final parents = members.where((m) => m.role == 'parent').length;

      // 今月の承認済み商品数
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final approvedItemsResponse = await _supabaseService.client
          .from('shopping_items')
          .select()
          .eq('status', 'approved')
          .gte('approved_at', monthStart.toIso8601String());

      final approvedItems = approvedItemsResponse.length;

      return {
        'totalMembers': members.length,
        'children': children,
        'parents': parents,
        'monthlyApprovedItems': approvedItems,
      };
    } catch (e) {
      throw ServerException(message: '家族統計の取得に失敗しました: $e');
    }
  }

  /// 招待コードを生成（6桁の英数字）
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }
}

/// 家族管理リポジトリプロバイダー

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return FamilyRepository(supabaseService);
});