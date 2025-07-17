import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart' as entities;
import '../../infrastructure/services/supabase_service.dart';
import '../../infrastructure/services/notification_service.dart';
import '../auth/auth_provider.dart';
import 'dart:async';

/// 通知状態
class NotificationState {
  final bool isLoading;
  final List<entities.Notification> notifications;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<entities.Notification>? notifications,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// 通知プロバイダー
class NotificationNotifier extends StateNotifier<NotificationState> {
  final SupabaseService _supabaseService;
  final NotificationService _notificationService;
  final Ref _ref;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  NotificationNotifier(this._supabaseService, this._notificationService, this._ref) 
      : super(const NotificationState()) {
    _initRealTimeListening();
  }

  /// リアルタイム監視を初期化
  void _initRealTimeListening() {
    _ref.listen(currentUserProvider, (previous, next) {
      if (next != null) {
        _startRealTimeListening(next.id);
      } else {
        _stopRealTimeListening();
      }
    });
  }

  /// リアルタイム監視を開始
  Future<void> _startRealTimeListening(String userId) async {
    try {
      // 既存の監視を停止
      await _stopRealTimeListening();

      // 初期データを取得
      await loadNotifications();

      // リアルタイム監視を開始
      _subscription = _supabaseService.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50)
          .listen(
            (data) {
              final notifications = data
                  .map((item) => entities.Notification.fromMap(item))
                  .toList();
              final unreadCount = notifications.where((n) => !n.isRead).length;
              
              state = state.copyWith(
                notifications: notifications,
                unreadCount: unreadCount,
                isLoading: false,
              );
            },
            onError: (error) {
              state = state.copyWith(
                error: 'リアルタイム通知の取得に失敗しました: $error',
                isLoading: false,
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        error: 'リアルタイム監視の開始に失敗しました: $e',
        isLoading: false,
      );
    }
  }

  /// リアルタイム監視を停止
  Future<void> _stopRealTimeListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// 通知一覧を取得
  Future<void> loadNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final response = await _supabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (response as List)
          .map((data) => entities.Notification.fromMap(data))
          .toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '通知の取得に失敗しました: $e',
      );
    }
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      // ローカル状態を更新
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        error: '通知の既読化に失敗しました: $e',
      );
    }
  }

  /// すべての通知を既読にする
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      // ローカル状態を更新
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(
          isRead: true,
          readAt: notification.readAt ?? DateTime.now(),
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(
        error: '通知の一括既読化に失敗しました: $e',
      );
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      // ローカル状態を更新
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        error: '通知の削除に失敗しました: $e',
      );
    }
  }

  /// 通知を作成
  Future<void> createNotification({
    required String userId,
    required String familyId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabaseService.client.from('notifications').insert({
        'user_id': userId,
        'family_id': familyId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('通知の作成に失敗しました: $e');
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _stopRealTimeListening();
    super.dispose();
  }
}

/// 通知プロバイダー
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  final notificationService = ref.read(notificationServiceProvider);
  return NotificationNotifier(supabaseService, notificationService, ref);
});

/// 未読通知数プロバイダー
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.unreadCount;
});