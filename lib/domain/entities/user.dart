import 'package:equatable/equatable.dart';

/// ユーザーエンティティ
class User extends Equatable {
  /// ユーザーID
  final String id;
  
  /// メールアドレス
  final String email;
  
  /// ユーザーロール
  final UserRole role;
  
  /// 名前
  final String? name;
  
  /// アバターURL
  final String? avatarUrl;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 更新日時
  final DateTime updatedAt;
  
  /// 削除日時（論理削除用）
  final DateTime? deletedAt;
  
  /// 最後の名前変更日時（子供のみ）
  final DateTime? lastNameChangeAt;
  
  /// 所属家族ID
  final String? familyId;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastNameChangeAt,
    this.familyId,
  });

  /// 名前変更可能かどうかを判定
  bool get canChangeName {
    if (lastNameChangeAt == null) return true;
    final now = DateTime.now();
    const changeInterval = Duration(days: 7);
    return now.difference(lastNameChangeAt!) >= changeInterval;
  }

  /// アクティブなユーザーかどうかを判定
  bool get isActive => deletedAt == null;

  /// 親かどうかを判定
  bool get isParent => role == UserRole.parent;

  /// 子供かどうかを判定
  bool get isChild => role == UserRole.child;

  /// 表示名を取得
  String get displayName => name ?? email;
  
  /// プロフィール写真URL（互換性のため）
  String? get photoUrl => avatarUrl;

  /// Mapからユーザーインスタンスを作成
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      role: UserRole.fromString(map['role'] as String),
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      lastNameChangeAt: map['last_name_change_at'] != null ? DateTime.parse(map['last_name_change_at'] as String) : null,
      familyId: map['family_id'] as String?,
    );
  }

  /// ユーザーをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'last_name_change_at': lastNameChangeAt?.toIso8601String(),
      'family_id': familyId,
    };
  }

  /// ユーザーをコピーして新しいインスタンスを作成
  User copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? lastNameChangeAt,
    String? familyId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastNameChangeAt: lastNameChangeAt ?? this.lastNameChangeAt,
      familyId: familyId ?? this.familyId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        name,
        avatarUrl,
        createdAt,
        updatedAt,
        deletedAt,
        lastNameChangeAt,
        familyId,
      ];
}

/// ユーザーロール列挙型
enum UserRole {
  /// 親
  parent,
  /// 子供
  child;

  /// 日本語表示名を取得
  String get displayName {
    switch (this) {
      case UserRole.parent:
        return '親';
      case UserRole.child:
        return '子ども';
    }
  }

  /// 英語名を取得
  String get name {
    switch (this) {
      case UserRole.parent:
        return 'parent';
      case UserRole.child:
        return 'child';
    }
  }

  /// 文字列からUserRoleを作成
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'parent':
        return UserRole.parent;
      case 'child':
        return UserRole.child;
      default:
        throw ArgumentError('Invalid UserRole: $value');
    }
  }
}