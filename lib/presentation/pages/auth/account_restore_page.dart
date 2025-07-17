import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/app_scaffold.dart';

/// アカウント復旧画面（機能無効化）
class AccountRestorePage extends ConsumerStatefulWidget {
  const AccountRestorePage({super.key});

  @override
  ConsumerState<AccountRestorePage> createState() => _AccountRestorePageState();
}

class _AccountRestorePageState extends ConsumerState<AccountRestorePage> {
  @override
  void initState() {
    super.initState();
    // ページ読み込み後、ログイン画面にリダイレクト
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'アカウント復旧',
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber,
                size: 80,
                color: Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                'アカウント復旧機能は利用できません',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'アカウント削除は即座に実行され、復旧はできません。\n\n新しいアカウントを作成してください。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}