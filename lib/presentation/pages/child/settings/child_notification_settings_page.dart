import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/auth/auth_provider.dart';
import '../../../../infrastructure/services/notification_service.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/loading_widget.dart';

/// 子用通知設定画面
class ChildNotificationSettingsPage extends ConsumerStatefulWidget {
  const ChildNotificationSettingsPage({super.key});

  @override
  ConsumerState<ChildNotificationSettingsPage> createState() => _ChildNotificationSettingsPageState();
}

class _ChildNotificationSettingsPageState extends ConsumerState<ChildNotificationSettingsPage> {
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
                  _buildAllowanceNotifications(),
                  const SizedBox(height: 24),
                  _buildShoppingNotifications(),
                  const SizedBox(height: 24),
                  _buildFamilyNotifications(),
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
              'どの種類の通知を受け取るかを設定できます。重要な通知（お小遣いや承認など）はオフにしないことをおすすめします。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
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
          subtitle: 'お小遣いがもらえた時',
          icon: Icons.account_balance_wallet,
          important: true,
        ),
        _buildNotificationItem(
          key: 'allowance_bonus',
          title: 'ボーナス通知',
          subtitle: 'ボーナスがもらえた時',
          icon: Icons.star,
          important: true,
        ),
      ],
    );
  }

  Widget _buildShoppingNotifications() {
    return _buildNotificationSection(
      title: '買い物関連',
      icon: Icons.shopping_cart,
      items: [
        _buildNotificationItem(
          key: 'item_approved',
          title: '承認通知',
          subtitle: 'リクエストした商品が承認された時',
          icon: Icons.thumb_up,
          important: true,
        ),
        _buildNotificationItem(
          key: 'item_rejected',
          title: '却下通知',
          subtitle: 'リクエストした商品が却下された時',
          icon: Icons.thumb_down,
          important: true,
        ),
        _buildNotificationItem(
          key: 'list_updated',
          title: 'リスト更新通知',
          subtitle: '買い物リストが更新された時',
          icon: Icons.update,
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
          key: 'family_message',
          title: '家族メッセージ',
          subtitle: '親からのメッセージ',
          icon: Icons.message,
        ),
        _buildNotificationItem(
          key: 'system_update',
          title: 'お知らせ',
          subtitle: 'アプリのお知らせ',
          icon: Icons.campaign,
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
    bool important = false,
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (important)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '重要',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
      trailing: Switch(
        value: isEnabled,
        onChanged: important && isEnabled
            ? null // 重要な通知がオンの場合は無効化不可
            : (value) {
                setState(() {
                  _settings[key] = value;
                });
              },
      ),
    );
  }
}