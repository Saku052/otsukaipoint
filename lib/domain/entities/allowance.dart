import 'package:equatable/equatable.dart';

/// お小遣い残高エンティティ
class AllowanceBalance extends Equatable {
  /// ID
  final String id;
  
  /// ユーザーID
  final String userId;
  
  /// 家族ID
  final String familyId;
  
  /// 残高
  final double balance;
  
  /// 最終更新日時
  final DateTime lastUpdatedAt;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 更新日時
  final DateTime updatedAt;

  const AllowanceBalance({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.balance,
    required this.lastUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 残高があるかどうかを判定
  bool get hasBalance => balance > 0;

  /// 残高が0以上かどうかを判定
  bool get isValidBalance => balance >= 0;

  /// お小遣い残高をコピーして新しいインスタンスを作成
  AllowanceBalance copyWith({
    String? id,
    String? userId,
    String? familyId,
    double? balance,
    DateTime? lastUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllowanceBalance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      balance: balance ?? this.balance,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 残高を追加
  AllowanceBalance addBalance(double amount) {
    return copyWith(
      balance: balance + amount,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// 残高を減算
  AllowanceBalance subtractBalance(double amount) {
    final newBalance = balance - amount;
    if (newBalance < 0) {
      throw ArgumentError('残高が不足しています');
    }
    return copyWith(
      balance: newBalance,
      lastUpdatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        familyId,
        balance,
        lastUpdatedAt,
        createdAt,
        updatedAt,
      ];
}

/// お小遣い取引履歴エンティティ
class AllowanceTransaction extends Equatable {
  /// ID
  final String id;
  
  /// ユーザーID
  final String userId;
  
  /// 家族ID
  final String familyId;
  
  /// 商品ID（お使い関連の場合）
  final String? shoppingItemId;
  
  /// 金額
  final double amount;
  
  /// 取引タイプ
  final TransactionType transactionType;
  
  /// 説明
  final String? description;
  
  /// 作成者ID
  final String? createdBy;
  
  /// 作成日時
  final DateTime createdAt;

  const AllowanceTransaction({
    required this.id,
    required this.userId,
    required this.familyId,
    this.shoppingItemId,
    required this.amount,
    required this.transactionType,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  /// 収入かどうかを判定
  bool get isIncome => transactionType == TransactionType.earned;

  /// 支出かどうかを判定
  bool get isExpense => transactionType == TransactionType.spent;

  /// 調整かどうかを判定
  bool get isAdjustment => transactionType == TransactionType.adjustment;

  /// お使い関連かどうかを判定
  bool get isShoppingRelated => shoppingItemId != null;

  /// お小遣い取引履歴をコピーして新しいインスタンスを作成
  AllowanceTransaction copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? shoppingItemId,
    double? amount,
    TransactionType? transactionType,
    String? description,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return AllowanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      shoppingItemId: shoppingItemId ?? this.shoppingItemId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        familyId,
        shoppingItemId,
        amount,
        transactionType,
        description,
        createdBy,
        createdAt,
      ];
}

/// 取引タイプ列挙型
enum TransactionType {
  /// 獲得
  earned,
  /// 使用
  spent,
  /// 調整
  adjustment;

  /// 日本語表示名を取得
  String get displayName {
    switch (this) {
      case TransactionType.earned:
        return '獲得';
      case TransactionType.spent:
        return '使用';
      case TransactionType.adjustment:
        return '調整';
    }
  }

  /// 英語名を取得
  String get name {
    switch (this) {
      case TransactionType.earned:
        return 'earned';
      case TransactionType.spent:
        return 'spent';
      case TransactionType.adjustment:
        return 'adjustment';
    }
  }

  /// アイコンを取得
  String get iconName {
    switch (this) {
      case TransactionType.earned:
        return 'add_circle';
      case TransactionType.spent:
        return 'remove_circle';
      case TransactionType.adjustment:
        return 'edit';
    }
  }

  /// 文字列からTransactionTypeを作成
  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'earned':
        return TransactionType.earned;
      case 'spent':
        return TransactionType.spent;
      case 'adjustment':
        return TransactionType.adjustment;
      default:
        throw ArgumentError('Invalid TransactionType: $value');
    }
  }
}