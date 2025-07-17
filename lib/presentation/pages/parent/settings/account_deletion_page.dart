import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_provider.dart';
import '../../../../infrastructure/services/account_deletion_service.dart';
import '../../../../infrastructure/services/supabase_service.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/loading_widget.dart';

/// アカウント削除ページ
class AccountDeletionPage extends ConsumerStatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  ConsumerState<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends ConsumerState<AccountDeletionPage> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedReason;
  bool _showPassword = false;
  bool _isLoading = false;
  bool _confirmDeletion = false;

  final List<String> _deletionReasons = [
    'アプリを使わなくなった',
    '他のアプリに移行する',
    '機能に満足できない',
    'プライバシーの懸念',
    '家族の状況が変わった',
    'テクニカルな問題',
    'その他',
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'アカウント削除',
      body: user == null
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWarningCard(context),
                    const SizedBox(height: 24),
                    _buildDeletionImpactCard(context, user),
                    const SizedBox(height: 24),
                    _buildReasonSelectionCard(context),
                    const SizedBox(height: 24),
                    _buildPasswordConfirmationCard(context),
                    const SizedBox(height: 24),
                    _buildFinalConfirmationCard(context),
                    const SizedBox(height: 32),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '重要な注意事項',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWarningItem('すべてのお小遣いデータが削除されます'),
            _buildWarningItem('買い物リストと履歴が削除されます'),
            _buildWarningItem('家族とのつながりが解除されます'),
            _buildWarningItem('この操作は即座に実行され、取り消しできません'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '削除後の復旧はできません',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.close,
            color: Colors.red.shade600,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionImpactCard(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '削除される情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              icon: Icons.person,
              title: 'アカウント情報',
              description: '${user.name} (${user.email})',
            ),
            _buildInfoItem(
              context,
              icon: Icons.family_restroom,
              title: '家族関係',
              description: '子どもアカウントとの関連付けが解除されます',
            ),
            _buildInfoItem(
              context,
              icon: Icons.shopping_cart,
              title: '買い物データ',
              description: 'すべての買い物リストとアイテム',
            ),
            _buildInfoItem(
              context,
              icon: Icons.account_balance_wallet,
              title: 'お小遣いデータ',
              description: '残高、履歴、取引記録',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSelectionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '削除理由（任意）',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'より良いサービス提供のため、差し支えなければ理由をお聞かせください',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _deletionReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return FilterChip(
                  label: Text(reason),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedReason = selected ? reason : null;
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordConfirmationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'パスワード確認',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '本人確認のため、現在のパスワードを入力してください',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'パスワード',
                hintText: '現在のパスワードを入力',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワードを入力してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalConfirmationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最終確認',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _confirmDeletion,
              onChanged: (value) {
                setState(() {
                  _confirmDeletion = value ?? false;
                });
              },
              title: const Text(
                '上記の内容を理解し、アカウントの削除に同意します',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'この操作は即座に実行され、取り消すことができません',
              ),
              activeColor: Colors.red,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canDelete() ? () => _handleDeleteAccount(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'アカウントを削除する',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'キャンセル',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canDelete() {
    return _confirmDeletion && 
           _passwordController.text.isNotEmpty && 
           !_isLoading;
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 アカウント削除開始');
      
      final user = ref.read(currentUserProvider);
      if (user == null) {
        print('❌ ユーザー情報が取得できません');
        throw Exception('ユーザー情報が取得できません');
      }
      
      print('👤 削除対象ユーザー詳細:');
      print('   ID: ${user.id}');
      print('   Email: ${user.email}');
      print('   Name: ${user.name}');
      print('   Role: ${user.role}');
      
      // Supabaseの現在認証されているユーザーも確認
      try {
        final supabaseUser = ref.read(supabaseServiceProvider).auth.currentUser;
        if (supabaseUser != null) {
          print('🔐 Supabaseの認証ユーザー:');
          print('   ID: ${supabaseUser.id}');
          print('   Email: ${supabaseUser.email}');
          print('   IDが一致: ${user.id == supabaseUser.id}');
        } else {
          print('❌ Supabaseで認証されていません');
        }
      } catch (e) {
        print('❌ Supabase認証確認エラー: $e');
      }

      try {
        final accountDeletionService = ref.read(accountDeletionServiceProvider);
        print('✅ AccountDeletionServiceの取得に成功');
        
        print('🔐 アカウント削除処理開始...');
        final result = await accountDeletionService.deleteAccount(
          userId: user.id,
          password: _passwordController.text,
          confirmationText: 'DELETE',
          reason: _selectedReason,
          // IPアドレスとユーザーエージェントは必要に応じて実装
        );
        
        print('✅ アカウント削除処理完了: success=${result.success}');

        if (result.success) {
          print('🔄 認証状態をクリア中...');
          // 認証状態をクリア
          await ref.read(authProvider.notifier).handleAccountDeletion();
          print('✅ 認証状態クリア完了');
          
          // 成功画面に遷移
          if (context.mounted) {
            final redirectUrl = '/account-deleted?deletedAt=${result.deletedAt.toIso8601String()}';
            print('🔄 成功画面に遷移: $redirectUrl');
            context.go(redirectUrl);
          }
        } else {
          print('❌ アカウント削除に失敗: result.success = false');
          throw Exception('アカウント削除処理が失敗しました');
        }
      } on StateError catch (e) {
        print('❌ StateError (プロバイダー初期化エラー): $e');
        throw Exception('アプリの初期化に問題があります: $e');
      } on Exception catch (e) {
        print('❌ Exception: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      print('❌ アカウント削除エラー: $e');
      print('❌ Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        String errorMessage = 'アカウント削除に失敗しました';
        
        if (e.toString().contains('初期化')) {
          errorMessage = 'アプリの初期化に問題があります。アプリを再起動してください。';
        } else if (e.toString().contains('ユーザー情報')) {
          errorMessage = 'ユーザー情報を取得できません。再度ログインしてください。';
        } else if (e.toString().contains('パスワード')) {
          errorMessage = 'パスワードが正しくありません。';
        } else {
          errorMessage = 'アカウント削除に失敗しました: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'ログを確認',
              textColor: Colors.white,
              onPressed: () {
                print('Error details: $e');
                print('Stack trace: $stackTrace');
              },
            ),
          ),
        );
      }
    }
  }
}