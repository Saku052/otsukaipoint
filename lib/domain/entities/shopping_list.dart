import 'package:equatable/equatable.dart';
import 'shopping_item.dart';

/// 買い物リストエンティティ
class ShoppingList extends Equatable {
  /// 買い物リストID
  final String id;
  
  /// 家族ID
  final String familyId;
  
  /// 作成者ID（作成した親のID）
  final String createdBy;
  
  /// タイトル
  final String title;
  
  /// 説明
  final String? description;
  
  /// 期限
  final DateTime? deadline;
  
  /// アクティブかどうか
  final bool isActive;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 更新日時
  final DateTime updatedAt;
  
  /// 削除日時（論理削除用）
  final DateTime? deletedAt;
  
  /// 商品リスト
  final List<ShoppingItem> items;

  const ShoppingList({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    this.description,
    this.deadline,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.items = const [],
  });

  /// 期限切れかどうかを判定
  bool get isExpired {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// 期限までの残り時間を取得
  Duration? get remainingTime {
    if (deadline == null) return null;
    final now = DateTime.now();
    if (now.isAfter(deadline!)) return Duration.zero;
    return deadline!.difference(now);
  }

  /// アクティブかどうかを判定
  bool get isActiveAndNotDeleted => isActive && deletedAt == null;

  /// Mapから買い物リストインスタンスを作成
  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    // デバッグ用：受信したマップの内容を出力
    print('🔍 ShoppingList.fromMap 受信データ: $map');
    
    final itemsList = map['shopping_items'] as List<dynamic>?;
    final items = itemsList?.map((item) => ShoppingItem.fromMap(item as Map<String, dynamic>)).toList() ?? <ShoppingItem>[];
    
    // null安全性を強化
    final id = map['id']?.toString() ?? '';
    final familyId = map['family_id']?.toString() ?? '';
    final createdBy = map['created_by']?.toString() ?? '';
    final title = map['title']?.toString() ?? '';
    final description = map['description']?.toString();
    final isActive = map['is_active'] as bool? ?? true;
    
    // 日時フィールドのnull安全性
    final createdAtStr = map['created_at']?.toString();
    final updatedAtStr = map['updated_at']?.toString();
    final deletedAtStr = map['deleted_at']?.toString();
    
    print('🔍 パース前データ: id=$id, familyId=$familyId, createdBy=$createdBy, title=$title');
    print('🔍 日時データ: createdAt=$createdAtStr, updatedAt=$updatedAtStr');
    
    return ShoppingList(
      id: id,
      familyId: familyId,
      createdBy: createdBy,
      title: title,
      description: description,
      deadline: null, // 一時的に無効化
      isActive: isActive,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now(),
      deletedAt: deletedAtStr != null ? DateTime.parse(deletedAtStr) : null,
      items: items,
    );
  }

  /// 買い物リストをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      // 'deadline': deadline?.toIso8601String(), // 一時的に無効化
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// 買い物リストをコピーして新しいインスタンスを作成
  ShoppingList copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ShoppingItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        createdBy,
        title,
        description,
        deadline,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
        items,
      ];
}