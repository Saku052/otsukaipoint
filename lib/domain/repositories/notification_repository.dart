import '../entities/notification.dart';

/// 通知リポジトリインターフェース
abstract class NotificationRepository {
  /// 通知一覧を取得
  Future<List<Notification>> getNotifications({
    String? userId,
    bool? isRead,
    int? limit,
  });
  
  /// 通知を取得
  Future<Notification?> getNotification(String notificationId);
  
  /// 通知を作成
  Future<String> createNotification(Notification notification);
  
  /// 通知を既読にする
  Future<void> markAsRead(String notificationId);
  
  /// すべての通知を既読にする
  Future<void> markAllAsRead(String userId);
  
  /// 通知を削除
  Future<void> deleteNotification(String notificationId);
  
  /// 未読通知数を取得
  Future<int> getUnreadCount(String userId);
  
  /// 通知設定を取得
  Future<Map<String, bool>> getNotificationSettings(String userId);
  
  /// 通知設定を更新
  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  });
}