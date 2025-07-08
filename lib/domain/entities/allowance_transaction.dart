import 'package:equatable/equatable.dart';

/// お小遣い取引エンティティ
class AllowanceTransaction extends Equatable {
  /// ID
  final String id;
  
  /// ユーザーID
  final String userId;
  
  /// 家族ID
  final String familyId;
  
  /// 関連する買い物アイテムID
  final String? shoppingItemId;
  
  /// 金額
  final double amount;
  
  /// 取引タイプ
  final String type;
  
  /// 説明
  final String description;
  
  /// 承認者ID
  final String? createdBy;
  
  /// 承認者名
  final String? approvedByName;
  
  /// 買い物リストタイトル
  final String? shoppingListTitle;
  
  /// 取引前残高
  final double balanceBefore;
  
  /// 取引後残高
  final double balanceAfter;
  
  /// 取引日時
  final DateTime transactionDate;
  
  /// 作成日時
  final DateTime createdAt;

  const AllowanceTransaction({
    required this.id,
    required this.userId,
    required this.familyId,
    this.shoppingItemId,
    required this.amount,
    required this.type,
    required this.description,
    this.createdBy,
    this.approvedByName,
    this.shoppingListTitle,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.transactionDate,
    required this.createdAt,
  });

  /// 取引をコピーして新しいインスタンスを作成
  AllowanceTransaction copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? shoppingItemId,
    double? amount,
    String? type,
    String? description,
    String? createdBy,
    String? approvedByName,
    String? shoppingListTitle,
    double? balanceBefore,
    double? balanceAfter,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return AllowanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      shoppingItemId: shoppingItemId ?? this.shoppingItemId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      approvedByName: approvedByName ?? this.approvedByName,
      shoppingListTitle: shoppingListTitle ?? this.shoppingListTitle,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 収入取引かどうかを判定
  bool get isIncome => type == 'earned' || type == 'bonus' || type == 'adjustment' && amount > 0;
  
  /// 支出取引かどうかを判定
  bool get isExpense => type == 'spent' || type == 'penalty' || type == 'adjustment' && amount < 0;

  /// Mapから取引インスタンスを作成
  factory AllowanceTransaction.fromMap(Map<String, dynamic> map) {
    return AllowanceTransaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      familyId: map['family_id'] as String,
      shoppingItemId: map['related_item_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      description: map['description'] as String,
      createdBy: map['created_by'] as String?,
      approvedByName: map['approved_by_name'] as String?,
      shoppingListTitle: map['shopping_list_title'] as String?,
      balanceBefore: (map['balance_before'] as num).toDouble(),
      balanceAfter: (map['balance_after'] as num).toDouble(),
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 取引をMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'family_id': familyId,
      'related_item_id': shoppingItemId,
      'amount': amount,
      'type': type,
      'description': description,
      'created_by': createdBy,
      'approved_by_name': approvedByName,
      'shopping_list_title': shoppingListTitle,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        familyId,
        shoppingItemId,
        amount,
        type,
        description,
        createdBy,
        approvedByName,
        shoppingListTitle,
        balanceBefore,
        balanceAfter,
        transactionDate,
        createdAt,
      ];
}

/// 取引タイプの定数
class TransactionType {
  static const String earned = 'earned';
  static const String spent = 'spent';
  static const String adjustment = 'adjustment';
  static const String bonus = 'bonus';
  static const String penalty = 'penalty';
}