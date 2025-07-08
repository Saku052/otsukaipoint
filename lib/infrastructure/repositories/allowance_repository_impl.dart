import '../../domain/entities/allowance_balance.dart';
import '../../domain/entities/allowance_transaction.dart';
import '../../domain/repositories/allowance_repository.dart';
import '../services/supabase_service.dart';

/// お小遣いリポジトリ実装
class AllowanceRepositoryImpl implements AllowanceRepository {
  final SupabaseService _supabaseService;

  AllowanceRepositoryImpl(this._supabaseService);

  @override
  Future<AllowanceBalance?> getBalance(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('allowance_balances')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return AllowanceBalance.fromMap(response);
    } catch (e) {
      throw Exception('残高の取得に失敗しました: $e');
    }
  }

  @override
  Future<void> updateBalance({
    required String userId,
    required String familyId,
    required double amount,
    required String type,
    required String description,
    String? adjustedBy,
  }) async {
    try {
      // 現在の残高を取得
      final currentBalance = await getBalance(userId);
      final balanceBefore = currentBalance?.balance ?? 0.0;
      
      double balanceAfter;
      double totalEarned = currentBalance?.totalEarned ?? 0.0;
      double totalSpent = currentBalance?.totalSpent ?? 0.0;

      if (type == 'add') {
        balanceAfter = balanceBefore + amount;
        totalEarned += amount;
      } else {
        balanceAfter = balanceBefore - amount;
        totalSpent += amount;
      }

      // 残高を更新または作成
      if (currentBalance != null) {
        await _supabaseService.client
            .from('allowance_balances')
            .update({
              'balance': balanceAfter,
              'total_earned': totalEarned,
              'total_spent': totalSpent,
              'last_updated_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        await _supabaseService.client.from('allowance_balances').insert({
          'user_id': userId,
          'family_id': familyId,
          'balance': balanceAfter,
          'total_earned': totalEarned,
          'total_spent': totalSpent,
          'last_updated_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 取引履歴を作成
      await _supabaseService.client.from('allowance_transactions').insert({
        'user_id': userId,
        'family_id': familyId,
        'amount': type == 'add' ? amount : -amount,
        'type': type == 'add' ? 'earned' : 'spent',
        'description': description,
        'created_by': adjustedBy,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('残高の更新に失敗しました: $e');
    }
  }

  @override
  Future<List<AllowanceTransaction>> getTransactions({
    String? userId,
    String? familyId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _supabaseService.client
          .from('allowance_transactions')
          .select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (familyId != null) {
        query = query.eq('family_id', familyId);
      }
      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }

      // orderとlimitは最後に適用
      final response = await query
          .order('transaction_date', ascending: false)
          .limit(limit ?? 50);
          
      return (response as List)
          .map((data) => AllowanceTransaction.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('取引履歴の取得に失敗しました: $e');
    }
  }

  @override
  Future<String> createTransaction(AllowanceTransaction transaction) async {
    try {
      final response = await _supabaseService.client
          .from('allowance_transactions')
          .insert(transaction.toMap())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('取引の作成に失敗しました: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAllowanceStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final balance = await getBalance(userId);
      final transactions = await getTransactions(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      double totalEarned = 0;
      double totalSpent = 0;
      int transactionCount = transactions.length;

      for (final transaction in transactions) {
        if (transaction.isIncome) {
          totalEarned += transaction.amount.abs();
        } else if (transaction.isExpense) {
          totalSpent += transaction.amount.abs();
        }
      }

      return {
        'current_balance': balance?.balance ?? 0.0,
        'total_earned': totalEarned,
        'total_spent': totalSpent,
        'transaction_count': transactionCount,
        'lifetime_earned': balance?.totalEarned ?? 0.0,
        'lifetime_spent': balance?.totalSpent ?? 0.0,
      };
    } catch (e) {
      throw Exception('統計の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<AllowanceBalance>> getFamilyAllowances(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('allowance_balances')
          .select()
          .eq('family_id', familyId);

      return (response as List)
          .map((data) => AllowanceBalance.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('家族のお小遣い一覧の取得に失敗しました: $e');
    }
  }
}