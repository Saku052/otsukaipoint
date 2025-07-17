import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isEmailLogin = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // 認証状態の監視
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // エラーをクリア
        Future.microtask(() => ref.read(authProvider.notifier).clearError());
      }
      
      // サインアップ成功時（メール確認待ち）のメッセージ
      if (previous?.isLoading == true && !next.isLoading && next.error == null && next.user == null && _isSignUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('アカウント作成が完了しました！\nメールアドレスに確認メールを送信しました。'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isSignUp = false; // サインアップモードをリセット
        });
      }
      
      // 認証成功時にロール選択画面に遷移
      if (next.user != null) {
        context.go(AppRouter.roleSelection);
      }
    });
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(context, authState),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          _buildHeader(context),
          const SizedBox(height: 60),
          _buildLoginOptions(context, authState),
          const SizedBox(height: 40),
          if (_isEmailLogin) ...[
            _buildEmailLoginForm(context, authState),
            const SizedBox(height: 24),
          ],
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_cart,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'おつかいポイント',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '家族でお使いを楽しもう',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginOptions(BuildContext context, AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Googleログインボタン
        AppButton(
          text: 'Googleでログイン',
          type: AppButtonType.outline,
          onPressed: authState.isLoading 
              ? null 
              : () => ref.read(authProvider.notifier).signInWithGoogle(),
          isLoading: authState.isLoading,
          icon: Icons.g_mobiledata,
          isFullWidth: true,
        ),
        
        const SizedBox(height: 16),
        
        // 区切り線
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'または',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // メールログインボタン
        AppButton(
          text: _isEmailLogin ? 'メールログインを閉じる' : 'メールでログイン',
          type: AppButtonType.outline,
          onPressed: () {
            setState(() {
              _isEmailLogin = !_isEmailLogin;
            });
          },
          icon: Icons.email_outlined,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm(BuildContext context, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // メールアドレス入力
          AppTextField(
            controller: _emailController,
            label: 'メールアドレス',
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'メールアドレスを入力してください';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return '正しいメールアドレスを入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // パスワード入力
          AppTextField(
            controller: _passwordController,
            label: 'パスワード',
            hint: '6文字以上',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
            onSuffixIconTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'パスワードを入力してください';
              }
              if (value.length < 6) {
                return 'パスワードは6文字以上で入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // ログイン/サインアップボタン
          AppButton(
            text: _isSignUp ? 'アカウント作成' : 'ログイン',
            onPressed: authState.isLoading ? null : _handleEmailAuth,
            isLoading: authState.isLoading,
            isFullWidth: true,
          ),
          
          const SizedBox(height: 16),
          
          // サインアップ/ログイン切り替え
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
              });
            },
            child: Text(
              _isSignUp 
                  ? 'すでにアカウントをお持ちの方はこちら'
                  : 'アカウントをお持ちでない方はこちら',
            ),
          ),
          
          // パスワードリセット
          if (!_isSignUp)
            TextButton(
              onPressed: _handlePasswordReset,
              child: const Text('パスワードを忘れた方はこちら'),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'ログインすることで利用規約とプライバシーポリシーに同意したものとします',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleEmailAuth() {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (_isSignUp) {
      ref.read(authProvider.notifier).signUpWithEmail(email, password);
    } else {
      ref.read(authProvider.notifier).signInWithEmail(email, password);
    }
  }

  void _handlePasswordReset() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メールアドレスを入力してからパスワードリセットをお試しください'),
        ),
      );
      return;
    }
    
    ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
  }
}