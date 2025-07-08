import 'package:equatable/equatable.dart';

/// アプリ内通知エンティティ
class AppNotification extends Equatable {
  /// 通知ID
  final String id;
  
  /// タイトル
  final String title;
  
  /// メッセージ
  final String message;
  
  /// 通知タイプ
  final NotificationType type;
  
  /// 優先度
  final NotificationPriority priority;
  
  /// 既読フラグ
  final bool isRead;
  
  /// 作成日時
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        priority,
        isRead,
        createdAt,
      ];
}

/// 通知タイプ列挙型
enum NotificationType {
  /// 情報通知
  info,
  /// 成功通知
  success,
  /// 警告通知
  warning,
  /// エラー通知
  error,
  /// システム通知
  system,
  /// お使い関連
  shopping;

  /// 日本語表示名を取得
  String get displayName {
    switch (this) {
      case NotificationType.info:
        return 'お知らせ';
      case NotificationType.success:
        return '成功';
      case NotificationType.warning:
        return '注意';
      case NotificationType.error:
        return 'エラー';
      case NotificationType.system:
        return 'システム';
      case NotificationType.shopping:
        return 'お使い';
    }
  }
}

/// 通知優先度列挙型
enum NotificationPriority {
  /// 低優先度
  low,
  /// 通常
  normal,
  /// 高優先度
  high,
  /// 緊急
  urgent;

  /// 日本語表示名を取得
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return '低';
      case NotificationPriority.normal:
        return '通常';
      case NotificationPriority.high:
        return '高';
      case NotificationPriority.urgent:
        return '緊急';
    }
  }
}