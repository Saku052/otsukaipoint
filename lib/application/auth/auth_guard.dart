import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import 'auth_provider.dart';

/// 認証ガード
/// 認証が必要なページへのアクセスを制御
class AuthGuard extends ConsumerWidget {
  /// 保護されたページ
  final Widget child;
  
  /// リダイレクト先（デフォルト: ログインページ）
  final String redirectTo;

  const AuthGuard({
    super.key,
    required this.child,
    this.redirectTo = AppRouter.login,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // 認証中の場合はローディング表示
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 未認証の場合はリダイレクト
    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(redirectTo);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 認証済みの場合は子ウィジェットを表示
    return child;
  }
}

/// 逆認証ガード（ログイン済みユーザーのアクセスを制限）
/// ログインページなどで使用
class AnonymousGuard extends ConsumerWidget {
  /// 匿名ユーザー向けページ
  final Widget child;
  
  /// リダイレクト先（デフォルト: ロール選択ページ）
  final String redirectTo;

  const AnonymousGuard({
    super.key,
    required this.child,
    this.redirectTo = AppRouter.roleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // 認証中の場合はローディング表示
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 認証済みの場合はリダイレクト
    if (authState.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ユーザーロールに基づいて適切なページにリダイレクト
        final userRole = authState.user!.role.name;
        switch (userRole) {
          case 'parent':
            context.go(AppRouter.parentDashboard);
            break;
          case 'child':
            context.go(AppRouter.childDashboard);
            break;
          default:
            context.go(redirectTo);
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 未認証の場合は子ウィジェットを表示
    return child;
  }
}

/// ロールベース認証ガード
/// 特定のロールのユーザーのみアクセス可能
class RoleGuard extends ConsumerWidget {
  /// 保護されたページ
  final Widget child;
  
  /// 許可されたロール
  final List<String> allowedRoles;
  
  /// アクセス拒否時のリダイレクト先
  final String redirectTo;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.redirectTo = AppRouter.roleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // 認証中の場合はローディング表示
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 未認証の場合はログインページにリダイレクト
    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRouter.login);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // ロールチェック
    final userRole = authState.user!.role.name;
    if (!allowedRoles.contains(userRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(redirectTo);
      });
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'アクセス権限がありません',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'このページにアクセスする権限がありません。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    // 認証済みかつ適切なロールの場合は子ウィジェットを表示
    return child;
  }
}

/// 認証状態監視ラッパー
/// アプリ全体で認証状態の変化を監視
class AuthStateListener extends ConsumerWidget {
  /// 子ウィジェット
  final Widget child;
  
  /// 認証成功時のコールバック
  final VoidCallback? onAuthenticated;
  
  /// 認証失敗時のコールバック
  final VoidCallback? onUnauthenticated;

  const AuthStateListener({
    super.key,
    required this.child,
    this.onAuthenticated,
    this.onUnauthenticated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      // 認証状態が変化した場合の処理
      if (previous?.user == null && next.user != null) {
        // 未認証 → 認証済み
        onAuthenticated?.call();
      } else if (previous?.user != null && next.user == null) {
        // 認証済み → 未認証
        onUnauthenticated?.call();
      }
    });
    
    return child;
  }
}