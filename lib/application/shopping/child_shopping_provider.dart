import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shopping_list.dart';
import '../../infrastructure/repositories/shopping_list_repository.dart';
import '../auth/auth_provider.dart';

/// 子ども用買い物リスト状態
class ChildShoppingState {
  final List<ShoppingList> assignedLists;
  final ShoppingList? selectedList;
  final bool isLoading;
  final String? error;

  const ChildShoppingState({
    this.assignedLists = const [],
    this.selectedList,
    this.isLoading = false,
    this.error,
  });

  ChildShoppingState copyWith({
    List<ShoppingList>? assignedLists,
    ShoppingList? selectedList,
    bool? isLoading,
    String? error,
  }) {
    return ChildShoppingState(
      assignedLists: assignedLists ?? this.assignedLists,
      selectedList: selectedList ?? this.selectedList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 子ども用買い物リスト管理クラス
class ChildShoppingNotifier extends StateNotifier<ChildShoppingState> {
  final ShoppingListRepository _repository;
  final Ref _ref;

  ChildShoppingNotifier(this._repository, this._ref) : super(const ChildShoppingState());

  /// 割り当てられた買い物リストを取得
  Future<void> loadAssignedShoppingLists() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final lists = await _repository.getAssignedShoppingLists(user.id);
      state = state.copyWith(
        assignedLists: lists,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 特定の買い物リストを取得
  Future<void> loadShoppingListDetail(String listId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final shoppingList = await _repository.getShoppingListById(listId);
      state = state.copyWith(
        selectedList: shoppingList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 商品を完了報告
  Future<bool> completeShoppingItem(String itemId, String userId, {String? photoUrl, String? note}) async {
    try {
      final result = await _repository.completeShoppingItem(
        itemId: itemId,
        completedBy: userId,
        photoUrl: photoUrl,
        note: note,
      );
      
      // 選択中のリストを更新
      if (state.selectedList != null) {
        await loadShoppingListDetail(state.selectedList!.id);
      }
      // 割り当てリストも更新
      await loadAssignedShoppingLists();
      
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
}

/// 子ども用買い物リストプロバイダー
final childShoppingProvider = StateNotifierProvider<ChildShoppingNotifier, ChildShoppingState>((ref) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return ChildShoppingNotifier(repository, ref);
});

/// 子ども用買い物リスト統計プロバイダー
final childShoppingStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  final repository = ref.watch(shoppingListRepositoryProvider);
  
  try {
    final lists = await repository.getAssignedShoppingLists(user.id);
    
    int totalLists = lists.length;
    int completedLists = 0;
    int totalItems = 0;
    int completedItems = 0;
    int approvedItems = 0;
    double totalEarnings = 0.0;

    // TODO: 商品リストが実装されるまで基本統計のみ
    // for (final list in lists) {
    //   totalItems += list.items.length;
    //   
    //   final listCompletedItems = list.items.where((item) => item.isCompleted).length;
    //   final listApprovedItems = list.items.where((item) => item.isApproved).length;
    //   
    //   completedItems += listCompletedItems;
    //   approvedItems += listApprovedItems;
    //   
    //   if (listCompletedItems == list.items.length && list.items.isNotEmpty) {
    //     completedLists++;
    //   }
    //   
    //   totalEarnings += list.items
    //       .where((item) => item.isApproved)
    //       .fold(0.0, (sum, item) => sum + item.allowanceAmount);
    // }

    return {
      'totalLists': totalLists,
      'completedLists': completedLists,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'approvedItems': approvedItems,
      'totalEarnings': totalEarnings.toInt(),
    };
  } catch (e) {
    return {};
  }
});

/// 進行中の買い物リストプロバイダー
final activeShoppingListsProvider = FutureProvider<List<ShoppingList>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(shoppingListRepositoryProvider);
  
  try {
    final lists = await repository.getAssignedShoppingLists(user.id);
    // TODO: 商品リストが実装されるまで全リストを返す
    return lists;
    // 未完了のリストのみを返す
    // return lists.where((list) {
    //   final totalItems = list.items.length;
    //   final completedItems = list.items.where((item) => item.isCompleted).length;
    //   return totalItems > 0 && completedItems < totalItems;
    // }).toList();
  } catch (e) {
    return [];
  }
});