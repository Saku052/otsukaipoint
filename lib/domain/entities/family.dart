import 'package:equatable/equatable.dart';

/// 家族エンティティ
class Family extends Equatable {
  /// 家族ID
  final String id;
  
  /// 家族名
  final String name;
  
  /// QRコード
  final String? qrCode;
  
  /// QRコード有効期限
  final DateTime? qrCodeExpiresAt;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 更新日時
  final DateTime updatedAt;
  
  /// 削除日時（論理削除用）
  final DateTime? deletedAt;

  const Family({
    required this.id,
    required this.name,
    this.qrCode,
    this.qrCodeExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// QRコードが有効かどうかを判定
  bool get isQrCodeValid {
    if (qrCode == null || qrCodeExpiresAt == null) return false;
    return DateTime.now().isBefore(qrCodeExpiresAt!);
  }

  /// アクティブな家族かどうかを判定
  bool get isActive => deletedAt == null;

  /// QRコードの残り時間を取得
  Duration? get qrCodeRemainingTime {
    if (qrCodeExpiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(qrCodeExpiresAt!)) return Duration.zero;
    return qrCodeExpiresAt!.difference(now);
  }

  /// 家族をコピーして新しいインスタンスを作成
  Family copyWith({
    String? id,
    String? name,
    String? qrCode,
    DateTime? qrCodeExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      qrCode: qrCode ?? this.qrCode,
      qrCodeExpiresAt: qrCodeExpiresAt ?? this.qrCodeExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// QRコードをクリア
  Family clearQrCode() {
    return copyWith(
      qrCode: null,
      qrCodeExpiresAt: null,
    );
  }

  /// Mapから家族インスタンスを作成
  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'] as String,
      name: map['name'] as String,
      qrCode: map['qr_code'] as String?,
      qrCodeExpiresAt: map['qr_code_expires_at'] != null ? DateTime.parse(map['qr_code_expires_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }

  /// 家族をMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'qr_code': qrCode,
      'qr_code_expires_at': qrCodeExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        qrCode,
        qrCodeExpiresAt,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

/// 家族メンバーエンティティ
class FamilyMember extends Equatable {
  /// ID
  final String id;
  
  /// 家族ID
  final String familyId;
  
  /// ユーザーID
  final String userId;
  
  /// ロール
  final String role;
  
  /// アクティブかどうか
  final bool isActive;
  
  /// 参加日時
  final DateTime joinedAt;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 更新日時
  final DateTime updatedAt;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.isActive,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 家族メンバーをコピーして新しいインスタンスを作成
  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? role,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mapからメンバーインスタンスを作成
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      isActive: map['is_active'] as bool? ?? true,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// メンバーをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role,
      'is_active': isActive,
      'joined_at': joinedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        userId,
        role,
        isActive,
        joinedAt,
        createdAt,
        updatedAt,
      ];
}