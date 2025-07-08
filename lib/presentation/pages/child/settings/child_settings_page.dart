import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_provider.dart';
// import '../../../../application/family/family_provider.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/loading_widget.dart';

/// 子用設定画面
class ChildSettingsPage extends ConsumerWidget {
  const ChildSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // final familyState = ref.watch(familyProvider);

    return AppScaffold(
      title: '設定',
      body: user == null 
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoSection(context, user),
                  const SizedBox(height: 24),
                  _buildMyAllowanceSection(context),
                  const SizedBox(height: 24),
                  _buildNotificationSection(context),
                  const SizedBox(height: 24),
                  _buildProfileSection(context),
                  const SizedBox(height: 24),
                  _buildAppSection(context),
                  const SizedBox(height: 24),
                  _buildAccountSection(context, ref),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.child_care,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'ユーザー',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '子アカウント',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
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

  Widget _buildMyAllowanceSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'マイお小遣い',
      icon: Icons.account_balance_wallet,
      items: [
        _buildSettingsItem(
          context,
          title: '残高確認',
          subtitle: '現在のお小遣い残高',
          icon: Icons.attach_money,
          onTap: () => context.push('/child/allowance'),
        ),
        _buildSettingsItem(
          context,
          title: '使用履歴',
          subtitle: 'お小遣いの使用履歴',
          icon: Icons.history,
          onTap: () => context.push('/child/allowance/history'),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: '通知設定',
      icon: Icons.notifications,
      items: [
        _buildSettingsItem(
          context,
          title: '通知設定',
          subtitle: '受け取る通知の種類を選択',
          icon: Icons.notification_important,
          onTap: () => context.push('/child/settings/notifications'),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'プロフィール',
      icon: Icons.person,
      items: [
        _buildSettingsItem(
          context,
          title: 'プロフィール編集',
          subtitle: '名前、アイコンの変更',
          icon: Icons.edit,
          onTap: () => context.push('/child/settings/profile'),
        ),
        _buildSettingsItem(
          context,
          title: '家族情報',
          subtitle: '所属している家族の情報',
          icon: Icons.family_restroom,
          onTap: () => context.push('/child/settings/family-info'),
        ),
      ],
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'アプリ設定',
      icon: Icons.settings,
      items: [
        _buildSettingsItem(
          context,
          title: 'テーマ設定',
          subtitle: 'ダークモード、色の設定',
          icon: Icons.palette,
          onTap: () => context.push('/child/settings/theme'),
        ),
        _buildSettingsItem(
          context,
          title: 'ヘルプ',
          subtitle: '使い方、よくある質問',
          icon: Icons.help,
          onTap: () => context.push('/child/settings/help'),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return _buildSettingsSection(
      context,
      title: 'アカウント',
      icon: Icons.account_circle,
      items: [
        _buildSettingsItem(
          context,
          title: 'プライバシー',
          subtitle: 'データの取り扱いについて',
          icon: Icons.privacy_tip,
          onTap: () => context.push('/child/settings/privacy'),
        ),
        _buildSettingsItem(
          context,
          title: 'ログアウト',
          subtitle: 'アプリからログアウト',
          icon: Icons.logout,
          iconColor: Colors.orange,
          onTap: () => _showLogoutDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth/signin');
              }
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}