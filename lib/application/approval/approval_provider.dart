import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shopping_item.dart';
import '../../infrastructure/repositories/shopping_list_repository.dart';
// import '../../infrastructure/providers/repository_providers.dart'; // 一時的に無効化
import '../auth/auth_provider.dart';

/// 承認状態
class ApprovalState {
  final List<ShoppingItem> pendingItems;
  final bool isLoading;
  final String? error;

  const ApprovalState({
    this.pendingItems = const [],
    this.isLoading = false,
    this.error,
  });

  ApprovalState copyWith({
    List<ShoppingItem>? pendingItems,
    bool? isLoading,
    String? error,
  }) {
    return ApprovalState(
      pendingItems: pendingItems ?? this.pendingItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 承認管理クラス
class ApprovalNotifier extends StateNotifier<ApprovalState> {
  final ShoppingListRepository _repository;
  final Ref _ref;

  ApprovalNotifier(this._repository, this._ref) : super(const ApprovalState());

  /// 承認待ち商品一覧を取得
  Future<void> loadPendingApprovalItems() async {
    final user = _ref.read(currentUserProvider);
    if (user == null || user.familyId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _repository.getPendingApprovalItems(user.familyId!);
      state = state.copyWith(
        pendingItems: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 商品を承認
  Future<bool> approveItem(String itemId, {String? approvalNote}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      // 商品情報を取得してお小遣いを付与
      final item = state.pendingItems.firstWhere((item) => item.id == itemId);
      
      // 商品を承認
      await _repository.approveShoppingItem(
        itemId: itemId,
        approvedBy: user.id,
      );

      // お小遣いを付与 (一時的に無効化)
      // if (item.completedBy != null) {
      //   try {
      //     await _allowanceRepository.addToBalance(
      //       userId: item.completedBy!,
      //       amount: item.allowanceAmount,
      //       description: '「${item.name}」の完了承認',
      //       relatedItemId: itemId,
      //       relatedShoppingListId: item.shoppingListId,
      //       approvedBy: user.id,
      //     );
      //   } catch (e) {
      //     // お小遣い付与に失敗してもエラーを表示（承認は成功したため）
      //     print('お小遣い付与に失敗しました: $e');
      //   }
      // }

      // 承認待ちリストを更新
      await loadPendingApprovalItems();
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 商品を拒否
  Future<bool> rejectItem(String itemId, {String? rejectionReason}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      await _repository.rejectShoppingItem(
        itemId: itemId,
        rejectedBy: user.id,
      );

      // 承認待ちリストを更新
      await loadPendingApprovalItems();
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 一括承認
  Future<bool> approveMultipleItems(List<String> itemIds) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      // 各商品を個別に承認してお小遣いを付与
      for (final itemId in itemIds) {
        final item = state.pendingItems.firstWhere((item) => item.id == itemId);
        
        // 商品を承認
        await _repository.approveShoppingItem(
          itemId: itemId,
          approvedBy: user.id,
        );

        // お小遣いを付与（一時的に無効化）
        // if (item.completedBy != null) {
        //   try {
        //     await _allowanceRepository.addToBalance(
        //       userId: item.completedBy!,
        //       amount: item.allowanceAmount,
        //       description: '「${item.name}」の完了承認',
        //       relatedItemId: itemId,
        //       relatedShoppingListId: item.shoppingListId,
        //       approvedBy: user.id,
        //     );
        //   } catch (e) {
        //     print('お小遣い付与に失敗しました (${item.name}): $e');
        //   }
        // }
      }

      // 承認待ちリストを更新
      await loadPendingApprovalItems();
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 特定の商品をローカル状態から削除（UI最適化用）
  void removeItemFromLocal(String itemId) {
    final updatedItems = state.pendingItems
        .where((item) => item.id != itemId)
        .toList();
    
    state = state.copyWith(pendingItems: updatedItems);
  }
}

/// 承認プロバイダー
final approvalProvider = StateNotifierProvider<ApprovalNotifier, ApprovalState>((ref) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return ApprovalNotifier(repository, ref);
});

/// 承認統計プロバイダー
final approvalStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.familyId == null) return {};

  final repository = ref.watch(shoppingListRepositoryProvider);
  
  try {
    final items = await repository.getPendingApprovalItems(user.familyId!);
    
    final totalPending = items.length;
    final todayPending = items.where((item) {
      final today = DateTime.now();
      final completedAt = item.completedAt;
      return completedAt != null &&
          completedAt.year == today.year &&
          completedAt.month == today.month &&
          completedAt.day == today.day;
    }).length;
    
    // 合計お小遣い金額
    final totalAllowance = items.fold<double>(
      0, 
      (sum, item) => sum + item.allowanceAmount,
    );

    return {
      'totalPending': totalPending,
      'todayPending': todayPending,
      'totalAllowance': totalAllowance.toInt(),
    };
  } catch (e) {
    return {};
  }
});

/// 子どもごとの承認待ち件数プロバイダー
final approvalByChildProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.familyId == null) return {};

  final repository = ref.watch(shoppingListRepositoryProvider);
  
  try {
    final items = await repository.getPendingApprovalItems(user.familyId!);
    
    final countByChild = <String, int>{};
    for (final item in items) {
      if (item.completedBy != null) {
        countByChild[item.completedBy!] = (countByChild[item.completedBy!] ?? 0) + 1;
      }
    }
    
    return countByChild;
  } catch (e) {
    return {};
  }
});