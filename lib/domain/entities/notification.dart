import 'package:equatable/equatable.dart';

/// 通知エンティティ
class Notification extends Equatable {
  /// 通知ID
  final String id;
  
  /// ユーザーID
  final String userId;
  
  /// 家族ID
  final String familyId;
  
  /// 通知タイプ
  final String type;
  
  /// タイトル
  final String title;
  
  /// メッセージ
  final String message;
  
  /// 追加データ
  final Map<String, dynamic>? data;
  
  /// 既読フラグ
  final bool isRead;
  
  /// 既読日時
  final DateTime? readAt;
  
  /// 作成日時
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  /// 通知をコピーして新しいインスタンスを作成
  Notification copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 未読かどうかを判定
  bool get isUnread => !isRead;

  /// 通知の重要度を判定
  NotificationPriority get priority {
    switch (type) {
      case 'item_approved':
      case 'item_rejected':
      case 'allowance_received':
        return NotificationPriority.high;
      case 'item_completed':
      case 'list_created':
        return NotificationPriority.medium;
      default:
        return NotificationPriority.low;
    }
  }

  /// Mapから通知インスタンスを作成
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      familyId: map['family_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['is_read'] as bool? ?? false,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 通知をMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'family_id': familyId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        familyId,
        type,
        title,
        message,
        data,
        isRead,
        readAt,
        createdAt,
      ];
}

/// 通知の重要度
enum NotificationPriority {
  low,
  medium,
  high,
}

/// 通知タイプの定数
class NotificationType {
  static const String itemAdded = 'item_added';
  static const String itemCompleted = 'item_completed';
  static const String itemApproved = 'item_approved';
  static const String itemRejected = 'item_rejected';
  static const String listCreated = 'list_created';
  static const String allowanceReceived = 'allowance_received';
  static const String familyInvitation = 'family_invitation';
  static const String systemUpdate = 'system_update';
}