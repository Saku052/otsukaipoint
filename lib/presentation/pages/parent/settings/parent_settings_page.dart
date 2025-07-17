import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_provider.dart';
import '../../../../application/family/family_provider.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/loading_widget.dart';

/// 親用設定画面
class ParentSettingsPage extends ConsumerWidget {
  const ParentSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final familyState = ref.watch(familyProvider);

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
                  _buildFamilyManagementSection(context, ref, familyState),
                  const SizedBox(height: 24),
                  _buildNotificationSection(context),
                  const SizedBox(height: 24),
                  _buildAllowanceSection(context),
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
                Icons.person,
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
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '親アカウント',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
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

  Widget _buildFamilyManagementSection(BuildContext context, WidgetRef ref, familyState) {
    return _buildSettingsSection(
      context,
      title: '家族管理',
      icon: Icons.family_restroom,
      items: [
        _buildSettingsItem(
          context,
          title: '家族メンバー管理',
          subtitle: '子アカウントの追加・管理',
          icon: Icons.people,
          onTap: () => context.push('/parent/settings/family-members'),
        ),
        _buildSettingsItem(
          context,
          title: 'QRコード生成',
          subtitle: '子を招待するためのQRコード',
          icon: Icons.qr_code,
          onTap: () => context.push('/parent/qr-code'),
        ),
        _buildSettingsItem(
          context,
          title: '家族設定',
          subtitle: '家族名の変更など',
          icon: Icons.settings,
          onTap: () => context.push('/parent/settings/family-settings'),
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
          onTap: () => context.push('/parent/settings/notifications'),
        ),
      ],
    );
  }

  Widget _buildAllowanceSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'お小遣い設定',
      icon: Icons.attach_money,
      items: [
        _buildSettingsItem(
          context,
          title: 'お小遣い管理',
          subtitle: '残高調整、履歴確認',
          icon: Icons.account_balance_wallet,
          onTap: () => context.push('/parent/settings/allowance'),
        ),
        _buildSettingsItem(
          context,
          title: 'ボーナス設定',
          subtitle: 'タスク完了時のボーナス額',
          icon: Icons.star,
          onTap: () => context.push('/parent/settings/bonus'),
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
          onTap: () => context.push('/parent/settings/theme'),
        ),
        _buildSettingsItem(
          context,
          title: 'データ管理',
          subtitle: 'キャッシュクリア、データエクスポート',
          icon: Icons.storage,
          onTap: () => context.push('/parent/settings/data'),
        ),
        _buildSettingsItem(
          context,
          title: 'ヘルプ・サポート',
          subtitle: 'FAQ、お問い合わせ',
          icon: Icons.help,
          onTap: () => context.push('/parent/settings/help'),
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
          title: 'プライバシー設定',
          subtitle: 'データの取り扱いについて',
          icon: Icons.privacy_tip,
          onTap: () => context.push('/parent/settings/privacy'),
        ),
        _buildSettingsItem(
          context,
          title: 'ログアウト',
          subtitle: 'アプリからログアウト',
          icon: Icons.logout,
          iconColor: Colors.orange,
          onTap: () => _showLogoutDialog(context, ref),
        ),
        _buildSettingsItem(
          context,
          title: 'アカウント削除',
          subtitle: '全データを削除してアカウントを削除',
          icon: Icons.delete_forever,
          iconColor: Colors.red,
          onTap: () => context.push('/parent/settings/account-deletion'),
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
              try {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ログアウトに失敗しました: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

}