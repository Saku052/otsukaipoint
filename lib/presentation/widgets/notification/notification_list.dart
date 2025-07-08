import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/notification/notification_provider.dart';
import '../../../domain/entities/notification.dart' as entities;
import '../common/loading_widget.dart';
import 'notification_tile.dart';

/// 通知リストウィジェット
class NotificationList extends ConsumerStatefulWidget {
  const NotificationList({super.key});

  @override
  ConsumerState<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<NotificationList> {
  @override
  void initState() {
    super.initState();
    // 初期データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    if (notificationState.isLoading && notificationState.notifications.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (notificationState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              notificationState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).loadNotifications();
              },
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (notificationState.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '通知はありません',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationProvider.notifier).loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: notificationState.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationState.notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDelete: () => _handleNotificationDelete(notification.id),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(entities.Notification notification) {
    // 通知を既読にする
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // 通知のタイプに応じてナビゲーション
    _navigateByNotificationType(notification);
  }

  void _navigateByNotificationType(entities.Notification notification) {
    // TODO: 通知タイプに応じた画面遷移を実装
    switch (notification.type) {
      case 'allowance_received':
        // お小遣い画面へ遷移
        break;
      case 'item_added':
      case 'item_completed':
        // 買い物リスト画面へ遷移
        break;
      case 'family_invitation':
        // 家族管理画面へ遷移
        break;
      default:
        // デフォルト動作
        break;
    }
  }

  void _handleNotificationDelete(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知を削除'),
        content: const Text('この通知を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationProvider.notifier).deleteNotification(notificationId);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}