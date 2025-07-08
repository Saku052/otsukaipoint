import 'package:flutter/material.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../core/utils/formatters.dart';
import '../common/app_card.dart';

/// 通知カード
class NotificationCard extends StatelessWidget {
  /// 通知情報
  final AppNotification notification;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// アクションボタンのコールバック
  final VoidCallback? onAction;
  
  /// 削除ボタンのコールバック
  final VoidCallback? onDelete;
  
  /// 既読にするコールバック
  final VoidCallback? onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onAction,
    this.onDelete,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildContent(context),
          const SizedBox(height: 12),
          _buildFooter(context),
          if (_hasActions()) ...[
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(context),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.formatRelativeTime(notification.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        _buildMenuButton(context),
      ],
    );
  }

  /// コンテンツ部分を構築
  Widget _buildContent(BuildContext context) {
    return Text(
      notification.message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// フッター部分を構築
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        _buildPriorityChip(context),
        const Spacer(),
        _buildTypeChip(context),
      ],
    );
  }

  /// アクション部分を構築
  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];
    
    if (onAction != null) {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: onAction,
            child: Text(_getActionText()),
          ),
        ),
      );
    }
    
    if (!notification.isRead && onMarkAsRead != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 8));
      }
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onMarkAsRead,
            child: const Text('既読にする'),
          ),
        ),
      );
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    
    return Row(children: actions);
  }

  /// タイプアイコンを構築
  Widget _buildTypeIcon(BuildContext context) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.shoppingCompleted:
        iconData = Icons.shopping_cart;
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case NotificationType.shoppingApproved:
        iconData = Icons.check_circle;
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case NotificationType.shoppingRejected:
        iconData = Icons.cancel;
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        iconColor = Theme.of(context).colorScheme.error;
        break;
      case NotificationType.familyInvitation:
        iconData = Icons.family_restroom;
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case NotificationType.allowanceReceived:
        iconData = Icons.account_balance_wallet;
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      case NotificationType.systemUpdate:
        iconData = Icons.system_update;
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        iconColor = Theme.of(context).colorScheme.onSurface;
        break;
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// 優先度チップを構築
  Widget _buildPriorityChip(BuildContext context) {
    if (notification.priority == NotificationPriority.low) {
      return const SizedBox.shrink();
    }
    
    Color backgroundColor;
    Color textColor;
    String label;
    
    switch (notification.priority) {
      case NotificationPriority.high:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        textColor = Theme.of(context).colorScheme.onErrorContainer;
        label = '重要';
        break;
      case NotificationPriority.medium:
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        textColor = Theme.of(context).colorScheme.onSecondaryContainer;
        label = '通常';
        break;
      case NotificationPriority.low:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// タイプチップを構築
  Widget _buildTypeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        notification.type.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// メニューボタンを構築
  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'read':
            onMarkAsRead?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (!notification.isRead)
          const PopupMenuItem(
            value: 'read',
            child: Row(
              children: [
                Icon(Icons.mark_email_read),
                SizedBox(width: 8),
                Text('既読にする'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('削除'),
            ],
          ),
        ),
      ],
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  /// アクションがあるかどうかを判定
  bool _hasActions() {
    return onAction != null || (!notification.isRead && onMarkAsRead != null);
  }

  /// アクションテキストを取得
  String _getActionText() {
    switch (notification.type) {
      case NotificationType.shoppingCompleted:
        return '承認/拒否';
      case NotificationType.familyInvitation:
        return '招待を確認';
      case NotificationType.allowanceReceived:
        return '履歴を見る';
      case NotificationType.shoppingApproved:
      case NotificationType.shoppingRejected:
      case NotificationType.systemUpdate:
        return '詳細を見る';
    }
  }
}