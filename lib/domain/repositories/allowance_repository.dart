import '../entities/allowance_balance.dart';
import '../entities/allowance_transaction.dart';

/// お小遣いリポジトリインターフェース
abstract class AllowanceRepository {
  /// 残高を取得
  Future<AllowanceBalance?> getBalance(String userId);
  
  /// 残高を更新
  Future<void> updateBalance({
    required String userId,
    required String familyId,
    required double amount,
    required String type, // 'add', 'subtract'
    required String description,
    String? adjustedBy,
  });
  
  /// 取引履歴を取得
  Future<List<AllowanceTransaction>> getTransactions({
    String? userId,
    String? familyId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  
  /// 取引を作成
  Future<String> createTransaction(AllowanceTransaction transaction);
  
  /// お小遣い統計を取得
  Future<Map<String, dynamic>> getAllowanceStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// 家族のお小遣い一覧を取得
  Future<List<AllowanceBalance>> getFamilyAllowances(String familyId);
}