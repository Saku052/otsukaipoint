import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/auth/auth_provider.dart';
import '../../../../infrastructure/services/notification_service.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/loading_widget.dart';

/// 通知設定画面
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  Map<String, bool> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final settings = await notificationService.getNotificationSettings(user.id);
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.updateNotificationSettings(
        userId: user.id,
        settings: _settings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('設定を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '通知設定',
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
      ],
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescriptionCard(),
                  const SizedBox(height: 24),
                  _buildShoppingNotifications(),
                  const SizedBox(height: 24),
                  _buildAllowanceNotifications(),
                  const SizedBox(height: 24),
                  _buildFamilyNotifications(),
                  const SizedBox(height: 24),
                  _buildSystemNotifications(),
                ],
              ),
            ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '通知設定について',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'どの種類の通知を受け取るかを設定できます。オフにした通知は表示されませんが、アプリ内の通知履歴では確認できます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingNotifications() {
    return _buildNotificationSection(
      title: '買い物関連',
      icon: Icons.shopping_cart,
      items: [
        _buildNotificationItem(
          key: 'item_added',
          title: '商品追加通知',
          subtitle: '子が買い物リストに商品を追加した時',
          icon: Icons.add_shopping_cart,
        ),
        _buildNotificationItem(
          key: 'item_completed',
          title: '商品完了通知',
          subtitle: '子が商品を購入完了にした時',
          icon: Icons.check_circle,
        ),
        _buildNotificationItem(
          key: 'item_approved',
          title: '承認完了通知',
          subtitle: '商品の承認が完了した時',
          icon: Icons.thumb_up,
        ),
        _buildNotificationItem(
          key: 'item_rejected',
          title: '却下通知',
          subtitle: '商品が却下された時',
          icon: Icons.thumb_down,
        ),
      ],
    );
  }

  Widget _buildAllowanceNotifications() {
    return _buildNotificationSection(
      title: 'お小遣い関連',
      icon: Icons.attach_money,
      items: [
        _buildNotificationItem(
          key: 'allowance_received',
          title: 'お小遣い受取通知',
          subtitle: 'お小遣いが付与された時',
          icon: Icons.account_balance_wallet,
        ),
        _buildNotificationItem(
          key: 'allowance_spent',
          title: 'お小遣い使用通知',
          subtitle: 'お小遣いが使用された時',
          icon: Icons.payment,
        ),
      ],
    );
  }

  Widget _buildFamilyNotifications() {
    return _buildNotificationSection(
      title: '家族関連',
      icon: Icons.family_restroom,
      items: [
        _buildNotificationItem(
          key: 'family_invitation',
          title: '家族参加通知',
          subtitle: '新しいメンバーが家族に参加した時',
          icon: Icons.person_add,
        ),
        _buildNotificationItem(
          key: 'list_created',
          title: 'リスト作成通知',
          subtitle: '新しい買い物リストが作成された時',
          icon: Icons.list_alt,
        ),
      ],
    );
  }

  Widget _buildSystemNotifications() {
    return _buildNotificationSection(
      title: 'システム',
      icon: Icons.settings,
      items: [
        _buildNotificationItem(
          key: 'system_update',
          title: 'システム更新通知',
          subtitle: 'アプリの更新やメンテナンス情報',
          icon: Icons.system_update,
        ),
        _buildNotificationItem(
          key: 'security_alert',
          title: 'セキュリティ通知',
          subtitle: '不正ログインなどのセキュリティ情報',
          icon: Icons.security,
        ),
      ],
    );
  }

  Widget _buildNotificationSection({
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

  Widget _buildNotificationItem({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isEnabled = _settings[key] ?? true;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
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
      trailing: Switch(
        value: isEnabled,
        onChanged: (value) {
          setState(() {
            _settings[key] = value;
          });
        },
      ),
    );
  }
}