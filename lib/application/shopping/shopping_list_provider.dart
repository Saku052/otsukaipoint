import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/shopping_item.dart';
import '../../infrastructure/repositories/shopping_list_repository.dart';
import '../auth/auth_provider.dart';
import '../family/family_provider.dart';

/// 買い物リスト状態
class ShoppingListState {
  /// ローディング状態
  final bool isLoading;

  /// 買い物リスト一覧
  final List<ShoppingList> lists;

  /// 現在選択されているリスト
  final ShoppingList? selectedList;

  /// エラーメッセージ
  final String? error;

  const ShoppingListState({
    this.isLoading = false,
    this.lists = const [],
    this.selectedList,
    this.error,
  });

  ShoppingListState copyWith({
    bool? isLoading,
    List<ShoppingList>? lists,
    ShoppingList? selectedList,
    String? error,
  }) {
    return ShoppingListState(
      isLoading: isLoading ?? this.isLoading,
      lists: lists ?? this.lists,
      selectedList: selectedList ?? this.selectedList,
      error: error ?? this.error,
    );
  }
}

/// 買い物リストNotifier
class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
  final ShoppingListRepository _repository;
  final Ref _ref;

  ShoppingListNotifier(this._repository, this._ref)
    : super(const ShoppingListState());

  /// 買い物リスト一覧を取得
  Future<void> loadShoppingLists() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;


    try {
      state = state.copyWith(isLoading: true, error: null);

      // 家族が存在することを確認
      final familyNotifier = _ref.read(familyProvider.notifier);
      await familyNotifier.ensureUserHasFamily();

      // 現在の家族を取得
      final currentFamily = await familyNotifier.getCurrentFamily();
      if (currentFamily == null) {
        throw Exception('家族情報が見つかりません');
      }

      final lists = await _repository.getShoppingLists(currentFamily.id);

      state = state.copyWith(isLoading: false, lists: lists, error: null);

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 特定の買い物リストを取得
  Future<void> loadShoppingList(String listId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final list = await _repository.getShoppingListWithItems(listId);

      state = state.copyWith(isLoading: false, selectedList: list, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 買い物リストを作成
  Future<ShoppingList?> createShoppingList({
    required String title,
    String? description,
    DateTime? deadline,
    List<Map<String, dynamic>>? items,
  }) async {
    final user = _ref.read(currentUserProvider);
    print('🛒 買い物リスト作成開始');
    print('👤 ユーザー情報: ${user?.id}');


    if (user == null) {
      print('❌ ユーザーが null です');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // 家族が存在することを確認
      final familyNotifier = _ref.read(familyProvider.notifier);
      await familyNotifier.ensureUserHasFamily();

      // 現在の家族を取得
      final currentFamily = await familyNotifier.getCurrentFamily();
      if (currentFamily == null) {
        throw Exception('家族情報が見つかりません。家族の作成に失敗しました。');
      }


      print('📝 リスト作成パラメータ:');
      print('  - タイトル: $title');
      print('  - 説明: $description');
      print('  - 期限: $deadline');
      print('  - 商品数: ${items?.length ?? 0}');
      print('  - 家族ID: ${currentFamily.id}');
      print('  - 作成者: ${user.id}');

      final newList = await _repository.createShoppingList(
        familyId: currentFamily.id,
        createdBy: user.id,
        title: title,
        description: description,
        deadline: deadline,
        items: items,
      );

      print('✅ 買い物リスト作成成功: ${newList.id}');

      // リスト一覧を更新（一時的に無効化）
      // await loadShoppingLists();
      
      // 統計プロバイダーのキャッシュを明示的に無効化
      _ref.invalidate(shoppingListStatsProvider);


      state = state.copyWith(
        isLoading: false,
        selectedList: newList,
        error: null,
      );

      return newList;
    } catch (e) {
      print('❌ 買い物リスト作成エラー: $e');
      print('❌ エラータイプ: ${e.runtimeType}');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// 買い物リストを更新
  Future<bool> updateShoppingList({
    required String listId,
    String? title,
    String? description,
    DateTime? deadline,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedList = await _repository.updateShoppingList(
        listId: listId,
        title: title,
        description: description,
        deadline: deadline,
      );

      // 現在選択されているリストを更新
      state = state.copyWith(
        isLoading: false,
        selectedList: updatedList,
        error: null,
      );

      // リスト一覧も更新
      await loadShoppingLists();

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 買い物リストを削除
  Future<bool> deleteShoppingList(String listId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteShoppingList(listId);

      // リスト一覧を更新
      await loadShoppingLists();

      // 選択されていたリストが削除された場合はクリア
      if (state.selectedList?.id == listId) {
        state = state.copyWith(selectedList: null);
      }

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 商品を追加
  Future<bool> addShoppingItem({
    required String shoppingListId,
    required String name,
    String? description,
    double? estimatedPrice,
    double allowanceAmount = 0,
    String? assignedTo,
    String? suggestedStore,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.addShoppingItem(
        shoppingListId: shoppingListId,
        name: name,
        description: description,
        estimatedPrice: estimatedPrice,
        allowanceAmount: allowanceAmount,
        assignedTo: assignedTo,
        suggestedStore: suggestedStore,
      );

      // 現在のリストを再取得
      await loadShoppingList(shoppingListId);


      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 商品を完了報告
  Future<bool> completeShoppingItem(String itemId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.completeShoppingItem(
        itemId: itemId,
        completedBy: user.id,
      );

      // 現在のリストを再取得
      if (state.selectedList != null) {
        await loadShoppingList(state.selectedList!.id);
        // 統計プロバイダーのキャッシュを明示的に無効化
        _ref.invalidate(shoppingListStatsProvider);
      }

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 商品を承認
  Future<bool> approveShoppingItem(String itemId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.approveShoppingItem(
        itemId: itemId,
        approvedBy: user.id,
      );

      // 現在のリストを再取得
      if (state.selectedList != null) {
        await loadShoppingList(state.selectedList!.id);
        // 統計プロバイダーのキャッシュを明示的に無効化
        _ref.invalidate(shoppingListStatsProvider);
      }

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 商品を拒否
  Future<bool> rejectShoppingItem(String itemId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.rejectShoppingItem(itemId: itemId, rejectedBy: user.id);

      // 現在のリストを再取得
      if (state.selectedList != null) {
        await loadShoppingList(state.selectedList!.id);
        // 統計プロバイダーのキャッシュを明示的に無効化
        _ref.invalidate(shoppingListStatsProvider);
      }

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 商品を更新
  Future<bool> updateShoppingItem({
    required String itemId,
    String? name,
    String? description,
    double? estimatedPrice,
    double? allowanceAmount,
    String? assignedTo,
    String? suggestedStore,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.updateShoppingItem(
        itemId: itemId,
        name: name,
        description: description,
        estimatedPrice: estimatedPrice,
        allowanceAmount: allowanceAmount,
        assignedTo: assignedTo,
        suggestedStore: suggestedStore,
      );

      // 現在のリストを再取得
      if (state.selectedList != null) {
        await loadShoppingList(state.selectedList!.id);
      }

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 商品を削除
  Future<bool> deleteShoppingItem(String itemId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _repository.deleteShoppingItem(itemId);

      // 現在のリストを再取得
      if (state.selectedList != null) {
        await loadShoppingList(state.selectedList!.id);
        // 統計プロバイダーのキャッシュを明示的に無効化
        _ref.invalidate(shoppingListStatsProvider);
      }

      state = state.copyWith(isLoading: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 承認待ち商品状態
class PendingApprovalState {
  /// ローディング状態
  final bool isLoading;

  /// 承認待ち商品一覧
  final List<ShoppingItem> items;

  /// エラーメッセージ
  final String? error;

  const PendingApprovalState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  PendingApprovalState copyWith({
    bool? isLoading,
    List<ShoppingItem>? items,
    String? error,
  }) {
    return PendingApprovalState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }
}

/// 承認待ち商品Notifier
class PendingApprovalNotifier extends StateNotifier<PendingApprovalState> {
  final ShoppingListRepository _repository;
  final Ref _ref;

  PendingApprovalNotifier(this._repository, this._ref)
    : super(const PendingApprovalState());

  /// 承認待ち商品一覧を取得
  Future<void> loadPendingApprovalItems() async {
    final user = _ref.read(currentUserProvider);
    if (user?.familyId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final items = await _repository.getPendingApprovalItems(user!.familyId!);

      state = state.copyWith(isLoading: false, items: items, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// 買い物リストプロバイダー
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, ShoppingListState>((ref) {
      final repository = ref.read(shoppingListRepositoryProvider);
      return ShoppingListNotifier(repository, ref);
    });

/// 承認待ち商品プロバイダー
final pendingApprovalProvider =
    StateNotifierProvider<PendingApprovalNotifier, PendingApprovalState>((ref) {
      final repository = ref.read(shoppingListRepositoryProvider);
      return PendingApprovalNotifier(repository, ref);
    });

/// 子供用買い物リストプロバイダー
final childShoppingListProvider = FutureProvider<List<ShoppingList>>((
  ref,
) async {
  final repository = ref.read(shoppingListRepositoryProvider);
  final user = ref.read(currentUserProvider);

  if (user == null) return [];

  return repository.getAssignedShoppingLists(user.id);
});

/// 買い物リスト統計プロバイダー
final shoppingListStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, listId) async {

      final repository = ref.read(shoppingListRepositoryProvider);
      return repository.getShoppingItemStats(listId);
    });
