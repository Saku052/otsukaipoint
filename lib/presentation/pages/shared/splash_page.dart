import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../application/auth/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startDelayedNavigation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.forward();
  }

  void _startDelayedNavigation() {
    // 最低限のスプラッシュ時間を待つ
    Future.delayed(const Duration(milliseconds: 2000)).then((_) {
      if (mounted && !_hasNavigated) {
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (_hasNavigated) return;
    
    final authState = ref.read(authProvider);
    
    // まだロード中の場合は待機
    if (authState.isLoading) return;
    
    _hasNavigated = true;
    
    if (authState.user != null) {
      // 認証済みの場合、ユーザーロールに基づいて遷移
      final userRole = authState.user!.role.name;
      switch (userRole) {
        case 'parent':
          context.go(AppRouter.parentDashboard);
          break;
        case 'child':
          context.go(AppRouter.childDashboard);
          break;
        default:
          context.go(AppRouter.roleSelection);
      }
    } else {
      // 未認証の場合はログインページに遷移
      context.go(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 現在の認証状態を監視（buildごとにチェック）
    final authState = ref.watch(authProvider);
    
    // 認証状態が変わった時のナビゲーション処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasNavigated && !authState.isLoading) {
        _checkAndNavigate();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '親子で楽しむお買い物アプリ',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 64),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}