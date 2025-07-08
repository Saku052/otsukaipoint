import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as app_user;
import '../../infrastructure/services/supabase_service.dart';

/// 認証状態
class AuthState {
  /// 認証中かどうか
  final bool isLoading;
  
  /// 現在のユーザー
  final app_user.User? user;
  
  /// エラーメッセージ
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    app_user.User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

/// 認証プロバイダー
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;

  AuthNotifier(this._supabaseService) : super(const AuthState()) {
    _initialize();
  }

  /// 初期化
  void _initialize() {
    // 認証状態の変更を監視
    _supabaseService.client.auth.onAuthStateChange.listen((data) async {
      try {
        final session = data.session;
        if (session != null) {
          await _handleUserSignedIn(session.user);
        } else {
          _handleUserSignedOut();
        }
      } catch (e) {
        print('Auth state change error: $e');
        state = state.copyWith(
          isLoading: false,
          error: '認証状態の更新中にエラーが発生しました: $e',
        );
      }
    });

    // 現在のセッションをチェック
    final currentSession = _supabaseService.client.auth.currentSession;
    if (currentSession != null) {
      _handleUserSignedIn(currentSession.user);
    }
  }

  /// ユーザーサインイン時の処理
  Future<void> _handleUserSignedIn(User supabaseUser) async {
    print('🔄 ユーザーサインイン処理開始: ${supabaseUser.id}');
    
    // 既に同じユーザーでサインイン済みの場合はスキップ
    if (state.user?.id == supabaseUser.id && !state.isLoading) {
      print('⏭️  既に同じユーザーでサインイン済みのためスキップ');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // ユーザー情報を取得またはプロファイルから変換
      final user = await _getUserFromSupabase(supabaseUser);
      
      print('✅ ユーザーサインイン処理完了: ${user.id}');
      
      state = state.copyWith(
        isLoading: false,
        user: user,
        error: null,
      );
    } catch (e) {
      print('❌ _handleUserSignedIn error: $e');
      print('❌ _handleUserSignedIn error type: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// ユーザーサインアウト時の処理
  void _handleUserSignedOut() {
    // 既にサインアウト状態の場合はスキップ
    if (state.user == null && !state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: false,
      user: null,
      error: null,
    );
  }

  /// Supabaseユーザーからアプリユーザーに変換
  Future<app_user.User> _getUserFromSupabase(User supabaseUser) async {
    try {
      print('👤 ユーザープロファイル取得開始: ${supabaseUser.id}');
      
      // データベースからユーザープロファイルを取得
      final response = await _supabaseService.client
          .from('user_profiles')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      print('👤 プロファイル取得結果: $response');

      if (response != null) {
        print('✅ 既存プロファイルが見つかりました');
        return app_user.User.fromMap(response);
      } else {
        print('📝 プロファイルが存在しないため新規作成します');
        
        // プロファイルが存在しない場合は基本情報で作成
        final newUser = app_user.User(
          id: supabaseUser.id,
          email: supabaseUser.email ?? '',
          name: supabaseUser.userMetadata?['full_name'] ?? supabaseUser.email?.split('@')[0] ?? '',
          avatarUrl: supabaseUser.userMetadata?['avatar_url'],
          role: app_user.UserRole.parent, // デフォルトは親
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('📝 新規ユーザー情報: id=${newUser.id}, email=${newUser.email}, name=${newUser.name}, role=${newUser.role.name}');

        // データベースにプロファイルを作成（user_profilesテーブル用のフィールドのみ）
        final insertData = {
          'id': newUser.id,
          'email': newUser.email,
          'name': newUser.name,
          'avatar_url': newUser.avatarUrl,
          'role': newUser.role.name,
          'is_active': true,
          'created_at': newUser.createdAt.toIso8601String(),
          'updated_at': newUser.updatedAt.toIso8601String(),
        };
        
        print('📝 データベース挿入データ: $insertData');
        
        await _supabaseService.client
            .from('user_profiles')
            .insert(insertData);

        print('✅ プロファイル作成完了');
        return newUser;
      }
    } catch (e) {
      print('❌ プロファイル取得/作成エラー: $e');
      print('❌ エラータイプ: ${e.runtimeType}');
      
      // エラーが発生した場合は基本情報のみで作成
      final fallbackUser = app_user.User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? '',
        name: supabaseUser.userMetadata?['full_name'] ?? supabaseUser.email?.split('@')[0] ?? '',
        avatarUrl: supabaseUser.userMetadata?['avatar_url'],
        role: app_user.UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('🔄 フォールバックユーザー作成: ${fallbackUser.id}');
      return fallbackUser;
    }
  }

  /// Googleでサインイン
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _supabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'jp.co.otsukaipoint://login-callback',
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '認証中にエラーが発生しました',
      );
    }
  }

  /// メールアドレスとパスワードでサインイン
  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ログイン中にエラーが発生しました',
      );
    }
  }

  /// メールアドレスとパスワードでサインアップ
  Future<void> signUpWithEmail(String email, String password, {
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('🔐 サインアップ開始: $email');
      print('🔐 displayName: $displayName');
      
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'full_name': displayName} : null,
      );

      print('🔐 サインアップレスポンス: user=${response.user?.id}, email=${response.user?.email}');
      print('🔐 emailConfirmed=${response.user?.emailConfirmedAt}');
      print('🔐 userMetadata=${response.user?.userMetadata}');

      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          // メール確認が必要
          print('📧 メール確認が必要');
          state = state.copyWith(
            isLoading: false,
            error: null,
          );
          // 成功メッセージとしてスナックバーを表示するため、errorは使わない
        } else {
          // メール確認不要（開発環境などで即座に確認済み）
          print('✅ メール確認済み、ユーザーサインイン処理開始');
          await _handleUserSignedIn(response.user!);
        }
      } else {
        // ユーザー作成失敗
        print('❌ ユーザー作成失敗: response.user is null');
        state = state.copyWith(
          isLoading: false,
          error: 'アカウント作成に失敗しました',
        );
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      print('❌ AuthException statusCode: ${e.statusCode}');
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
    } catch (e) {
      print('❌ SignUp error: $e');
      print('❌ SignUp error type: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: 'アカウント作成中にエラーが発生しました: $e',
      );
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _supabaseService.client.auth.signOut();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ログアウト中にエラーが発生しました',
      );
    }
  }

  /// パスワードリセットメール送信
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'jp.co.otsukaipoint://reset-password',
      );

      state = state.copyWith(
        isLoading: false,
        error: 'パスワードリセットメールを送信しました',
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getAuthErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'パスワードリセット中にエラーが発生しました',
      );
    }
  }

  /// ユーザープロファイル更新
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    app_user.UserRole? role,
  }) async {
    if (state.user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final updates = <String, dynamic>{};
      if (displayName != null) updates['name'] = displayName;
      if (photoUrl != null) updates['avatar_url'] = photoUrl;
      if (role != null) updates['role'] = role.name;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabaseService.client
          .from('user_profiles')
          .update(updates)
          .eq('id', state.user!.id);

      // ローカル状態を更新
      final updatedUser = state.user!.copyWith(
        name: displayName ?? state.user!.name,
        avatarUrl: photoUrl ?? state.user!.avatarUrl,
        role: role ?? state.user!.role,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'プロファイル更新中にエラーが発生しました',
      );
    }
  }

  /// 認証エラーメッセージを取得
  String _getAuthErrorMessage(AuthException exception) {
    switch (exception.message) {
      case 'Invalid login credentials':
        return 'メールアドレスまたはパスワードが間違っています';
      case 'Email not confirmed':
        return 'メールアドレスが確認されていません';
      case 'User already registered':
        return 'このメールアドレスは既に登録されています';
      case 'Password should be at least 6 characters':
        return 'パスワードは6文字以上で入力してください';
      case 'Unable to validate email address: invalid format':
        return 'メールアドレスの形式が正しくありません';
      case 'Network request failed':
        return 'ネットワークエラーが発生しました';
      default:
        return exception.message;
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return AuthNotifier(supabaseService);
});

/// 現在のユーザープロバイダー
final currentUserProvider = Provider<app_user.User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// 認証済みかどうかのプロバイダー
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user != null;
});

/// 認証中かどうかのプロバイダー
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoading;
});