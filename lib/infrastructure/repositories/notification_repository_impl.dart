import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/supabase_service.dart';

/// 通知リポジトリ実装
class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseService _supabaseService;

  NotificationRepositoryImpl(this._supabaseService);

  @override
  Future<List<Notification>> getNotifications({
    String? userId,
    bool? isRead,
    int? limit,
  }) async {
    try {
      var query = _supabaseService.client
          .from('notifications')
          .select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit ?? 50);
      return (response as List)
          .map((data) => Notification.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('通知の取得に失敗しました: $e');
    }
  }

  @override
  Future<Notification?> getNotification(String notificationId) async {
    try {
      final response = await _supabaseService.client
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .maybeSingle();

      if (response == null) return null;
      return Notification.fromMap(response);
    } catch (e) {
      throw Exception('通知の取得に失敗しました: $e');
    }
  }

  @override
  Future<String> createNotification(Notification notification) async {
    try {
      final response = await _supabaseService.client
          .from('notifications')
          .insert(notification.toMap())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('通知の作成に失敗しました: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('通知の既読化に失敗しました: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('通知の一括既読化に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('通知の削除に失敗しました: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('未読通知数の取得に失敗しました: $e');
    }
  }

  @override
  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // デフォルト設定を返す
        return {
          'item_added': true,
          'item_completed': true,
          'item_approved': true,
          'item_rejected': true,
          'list_created': true,
        };
      }

      return {
        'item_added': response['item_added'] as bool? ?? true,
        'item_completed': response['item_completed'] as bool? ?? true,
        'item_approved': response['item_approved'] as bool? ?? true,
        'item_rejected': response['item_rejected'] as bool? ?? true,
        'list_created': response['list_created'] as bool? ?? true,
      };
    } catch (e) {
      throw Exception('通知設定の取得に失敗しました: $e');
    }
  }

  @override
  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  }) async {
    try {
      final existingSettings = await _supabaseService.client
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final data = {
        'user_id': userId,
        'item_added': settings['item_added'] ?? true,
        'item_completed': settings['item_completed'] ?? true,
        'item_approved': settings['item_approved'] ?? true,
        'item_rejected': settings['item_rejected'] ?? true,
        'list_created': settings['list_created'] ?? true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingSettings != null) {
        await _supabaseService.client
            .from('notification_settings')
            .update(data)
            .eq('user_id', userId);
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
        await _supabaseService.client
            .from('notification_settings')
            .insert(data);
      }
    } catch (e) {
      throw Exception('通知設定の更新に失敗しました: $e');
    }
  }
}