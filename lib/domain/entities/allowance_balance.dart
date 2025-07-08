import 'package:equatable/equatable.dart';

/// お小遣い残高エンティティ
class AllowanceBalance extends Equatable {
  /// ID
  final String id;
  
  /// ユーザーID
  final String userId;
  
  /// 家族ID
  final String familyId;
  
  /// 現在残高
  final double balance;
  
  /// 累計獲得額
  final double totalEarned;
  
  /// 累計使用額
  final double totalSpent;
  
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
    required this.totalEarned,
    required this.totalSpent,
    required this.lastUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 残高をコピーして新しいインスタンスを作成
  AllowanceBalance copyWith({
    String? id,
    String? userId,
    String? familyId,
    double? balance,
    double? totalEarned,
    double? totalSpent,
    DateTime? lastUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllowanceBalance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 残高が十分かチェック
  bool canSpend(double amount) => balance >= amount;

  /// Mapから残高インスタンスを作成
  factory AllowanceBalance.fromMap(Map<String, dynamic> map) {
    return AllowanceBalance(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      familyId: map['family_id'] as String,
      balance: (map['balance'] as num).toDouble(),
      totalEarned: (map['total_earned'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      lastUpdatedAt: DateTime.parse(map['last_updated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 残高をMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'family_id': familyId,
      'balance': balance,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        familyId,
        balance,
        totalEarned,
        totalSpent,
        lastUpdatedAt,
        createdAt,
        updatedAt,
      ];
}