import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/allowance_balance.dart';
import '../../domain/entities/allowance_transaction.dart';
// import '../../infrastructure/providers/repository_providers.dart'; // 一時的に無効化
import '../../domain/repositories/allowance_repository.dart';
import '../auth/auth_provider.dart';

/// お小遣い状態
class AllowanceState {
  /// 残高情報
  final AllowanceBalance? balance;
  
  /// 取引履歴
  final List<AllowanceTransaction> transactions;
  
  /// ローディング状態
  final bool isLoading;
  
  /// エラーメッセージ
  final String? error;

  const AllowanceState({
    this.balance,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  AllowanceState copyWith({
    AllowanceBalance? balance,
    List<AllowanceTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return AllowanceState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// お小遣い管理クラス（一時的に無効化）
class AllowanceNotifier extends StateNotifier<AllowanceState> {
  final AllowanceRepository _repository;
  final Ref _ref;

  AllowanceNotifier(this._repository, this._ref) : super(const AllowanceState());

  /// ユーザーの残高と履歴を取得
  Future<void> loadUserAllowanceData() async {
    // 一時的にダミーデータを返す
    state = state.copyWith(
      balance: null,
      transactions: [],
      isLoading: false,
      error: null,
    );
  }

  /// 残高を更新
  Future<void> refreshBalance() async {
    // 一時的に何もしない
  }

  /// 取引履歴を更新
  Future<void> refreshTransactions() async {
    // 一時的に何もしない
  }

  /// お小遣いを使用
  Future<bool> spendAllowance(double amount, String description) async {
    // 一時的に成功を返す
    return true;
  }

  /// 商品承認時にお小遣いを付与
  Future<bool> addAllowanceFromApprovedItem({
    required double amount,
    required String itemName,
    required String itemId,
    required String shoppingListId,
    required String approvedBy,
  }) async {
    // 一時的に成功を返す
    return true;
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 一時的なダミーリポジトリプロバイダー
final _dummyAllowanceRepositoryProvider = Provider<AllowanceRepository>((ref) {
  // ダミー実装を返す
  throw UnimplementedError('AllowanceRepository not implemented yet');
});

/// お小遣いプロバイダー
final allowanceProvider = StateNotifierProvider<AllowanceNotifier, AllowanceState>((ref) {
  final repository = ref.watch(_dummyAllowanceRepositoryProvider);
  return AllowanceNotifier(repository, ref);
});

/// お小遣い統計プロバイダー
final allowanceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 一時的にダミーデータを返す
  return {
    'totalBalance': 500,
    'monthlyEarned': 300,
    'monthlySpent': 150,
  };
});

/// 家族の残高一覧プロバイダー（親用）
final familyBalancesProvider = FutureProvider<List<AllowanceBalance>>((ref) async {
  // 一時的に空リストを返す
  return <AllowanceBalance>[];
});