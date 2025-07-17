import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../providers/repository_providers.dart';
import 'supabase_service.dart';
import 'dart:async';

/// リアルタイム通知サービス
class NotificationService {
  final SupabaseService _supabaseService;
  final NotificationRepository _notificationRepository;
  
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  final StreamController<List<Notification>> _notificationStreamController = 
      StreamController<List<Notification>>.broadcast();

  NotificationService(this._supabaseService, this._notificationRepository);

  /// 通知ストリーム（リアルタイム）
  Stream<List<Notification>> get notificationStream => 
      _notificationStreamController.stream;

  /// 指定したユーザーの通知をリアルタイムで監視開始
  Future<void> startListening(String userId) async {
    try {
      // 既存の監視を停止
      await stopListening();

      // 初期データを取得
      final initialNotifications = await _notificationRepository.getNotifications(
        userId: userId,
        limit: 50,
      );
      _notificationStreamController.add(initialNotifications);

      // リアルタイム監視を開始
      _subscription = _supabaseService.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50)
          .listen(
            (data) async {
              final notifications = data
                  .map((item) => Notification.fromMap(item))
                  .toList();
              _notificationStreamController.add(notifications);
            },
            onError: (error) {
              // ログレベルのエラー処理に置き換える予定
            },
          );
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      rethrow;
    }
  }

  /// 通知監視を停止
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      rethrow;
    }
  }

  /// 全通知を既読にする
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationRepository.markAllAsRead(userId);
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      rethrow;
    }
  }

  /// 未読通知数を取得
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _notificationRepository.getUnreadCount(userId);
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      return 0;
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      rethrow;
    }
  }

  /// 通知設定を取得
  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    try {
      return await _notificationRepository.getNotificationSettings(userId);
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      return {
        'item_added': true,
        'item_completed': true,
        'item_approved': true,
        'item_rejected': true,
        'list_created': true,
      };
    }
  }

  /// 通知設定を更新
  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  }) async {
    try {
      await _notificationRepository.updateNotificationSettings(
        userId: userId,
        settings: settings,
      );
    } catch (e) {
      // ログレベルのエラー処理に置き換える予定
      rethrow;
    }
  }

  /// リソースを解放
  void dispose() {
    _subscription?.cancel();
    _notificationStreamController.close();
  }
}

/// 通知サービスプロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  final notificationRepository = ref.read(notificationRepositoryProvider);
  return NotificationService(supabaseService, notificationRepository);
});

/// 通知ストリームプロバイダー
final notificationStreamProvider = StreamProvider.family<List<Notification>, String>((ref, userId) {
  final notificationService = ref.read(notificationServiceProvider);
  
  // ユーザーIDが変更されたときに監視を開始
  notificationService.startListening(userId);
  
  // プロバイダーが破棄されるときに監視を停止
  ref.onDispose(() {
    notificationService.stopListening();
  });
  
  return notificationService.notificationStream;
});

/// 未読通知数プロバイダー
final unreadNotificationCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getUnreadCount(userId);
});

/// 通知設定プロバイダー
final notificationSettingsProvider = FutureProvider.family<Map<String, bool>, String>((ref, userId) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getNotificationSettings(userId);
});