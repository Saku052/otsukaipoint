import 'package:equatable/equatable.dart';

/// 買い物商品エンティティ
class ShoppingItem extends Equatable {
  /// 商品ID
  final String id;
  
  /// 買い物リストID
  final String shoppingListId;
  
  /// 商品名
  final String name;
  
  /// 説明
  final String? description;
  
  /// 予想価格
  final double? estimatedPrice;
  
  /// 推奨店舗
  final String? suggestedStore;
  
  /// お小遣い金額
  final double allowanceAmount;
  
  /// ステータス
  final ItemStatus status;
  
  /// 担当者ID（子供）
  final String? assignedTo;
  
  /// 完了者ID（子供）
  final String? completedBy;
  
  /// 完了日時
  final DateTime? completedAt;
  
  /// 承認者ID（親）
  final String? approvedBy;
  
  /// 承認日時
  final DateTime? approvedAt;
  
  /// 完了メモ
  final String? completionNote;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 更新日時
  final DateTime updatedAt;
  
  /// 削除日時（論理削除用）
  final DateTime? deletedAt;

  const ShoppingItem({
    required this.id,
    required this.shoppingListId,
    required this.name,
    this.description,
    this.estimatedPrice,
    this.suggestedStore,
    required this.allowanceAmount,
    required this.status,
    this.assignedTo,
    this.completedBy,
    this.completedAt,
    this.approvedBy,
    this.approvedAt,
    this.completionNote,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// 保留中かどうかを判定
  bool get isPending => status == ItemStatus.pending;

  /// 完了済みかどうかを判定
  bool get isCompleted => status == ItemStatus.completed || status == ItemStatus.approved || status == ItemStatus.rejected;

  /// 承認済みかどうかを判定
  bool get isApproved => status == ItemStatus.approved;

  /// 拒否済みかどうかを判定
  bool get isRejected => status == ItemStatus.rejected;

  /// 承認待ちかどうかを判定
  bool get isPendingApproval => status == ItemStatus.completed;

  /// 担当者が決まっているかどうかを判定
  bool get isAssigned => assignedTo != null;

  /// アクティブかどうかを判定
  bool get isActive => deletedAt == null;

  /// Mapから商品インスタンスを作成
  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as String,
      shoppingListId: map['shopping_list_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      estimatedPrice: map['estimated_price'] != null ? (map['estimated_price'] as num).toDouble() : null,
      suggestedStore: map['suggested_store'] as String?,
      allowanceAmount: (map['allowance_amount'] as num?)?.toDouble() ?? 0.0,
      status: ItemStatus.fromString(map['status'] as String),
      assignedTo: map['assigned_to'] as String?,
      completedBy: map['completed_by'] as String?,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at'] as String) : null,
      completionNote: map['completion_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }

  /// 商品をMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'name': name,
      'description': description,
      'estimated_price': estimatedPrice,
      'suggested_store': suggestedStore,
      'allowance_amount': allowanceAmount,
      'status': status.name,
      'assigned_to': assignedTo,
      'completed_by': completedBy,
      'completed_at': completedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'completion_note': completionNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// 商品をコピーして新しいインスタンスを作成
  ShoppingItem copyWith({
    String? id,
    String? shoppingListId,
    String? name,
    String? description,
    double? estimatedPrice,
    String? suggestedStore,
    double? allowanceAmount,
    ItemStatus? status,
    String? assignedTo,
    String? completedBy,
    DateTime? completedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? completionNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      suggestedStore: suggestedStore ?? this.suggestedStore,
      allowanceAmount: allowanceAmount ?? this.allowanceAmount,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      completionNote: completionNote ?? this.completionNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// 商品を完了状態にする
  ShoppingItem markAsCompleted(String childId) {
    return copyWith(
      status: ItemStatus.completed,
      completedBy: childId,
      completedAt: DateTime.now(),
    );
  }

  /// 商品を承認状態にする
  ShoppingItem markAsApproved(String parentId) {
    return copyWith(
      status: ItemStatus.approved,
      approvedBy: parentId,
      approvedAt: DateTime.now(),
    );
  }

  /// 商品を拒否状態にする
  ShoppingItem markAsRejected(String parentId) {
    return copyWith(
      status: ItemStatus.rejected,
      approvedBy: parentId,
      approvedAt: DateTime.now(),
    );
  }

  /// 商品を担当者に割り当て
  ShoppingItem assignTo(String childId) {
    return copyWith(assignedTo: childId);
  }

  @override
  List<Object?> get props => [
        id,
        shoppingListId,
        name,
        description,
        estimatedPrice,
        suggestedStore,
        allowanceAmount,
        status,
        assignedTo,
        completedBy,
        completedAt,
        approvedBy,
        approvedAt,
        completionNote,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

/// 商品ステータス列挙型
enum ItemStatus {
  /// 保留中
  pending,
  /// 完了済み（承認待ち）
  completed,
  /// 承認済み
  approved,
  /// 拒否済み
  rejected;

  /// 日本語表示名を取得
  String get displayName {
    switch (this) {
      case ItemStatus.pending:
        return '待機中';
      case ItemStatus.completed:
        return '完了報告済み';
      case ItemStatus.approved:
        return '承認済み';
      case ItemStatus.rejected:
        return '拒否済み';
    }
  }

  /// 英語名を取得
  String get name {
    switch (this) {
      case ItemStatus.pending:
        return 'pending';
      case ItemStatus.completed:
        return 'completed';
      case ItemStatus.approved:
        return 'approved';
      case ItemStatus.rejected:
        return 'rejected';
    }
  }

  /// ステータスカラーを取得
  String get colorHex {
    switch (this) {
      case ItemStatus.pending:
        return '#FF9800'; // オレンジ
      case ItemStatus.completed:
        return '#2196F3'; // ブルー
      case ItemStatus.approved:
        return '#4CAF50'; // グリーン
      case ItemStatus.rejected:
        return '#D32F2F'; // レッド
    }
  }

  /// 文字列からItemStatusを作成
  static ItemStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ItemStatus.pending;
      case 'completed':
        return ItemStatus.completed;
      case 'approved':
        return ItemStatus.approved;
      case 'rejected':
        return ItemStatus.rejected;
      default:
        throw ArgumentError('Invalid ItemStatus: $value');
    }
  }
}