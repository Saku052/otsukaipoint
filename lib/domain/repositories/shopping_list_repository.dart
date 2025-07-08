import '../entities/shopping_list.dart';
import '../entities/shopping_item.dart';

/// 買い物リストリポジトリインターフェース
abstract class ShoppingListRepository {
  /// 買い物リスト一覧を取得
  Future<List<ShoppingList>> getShoppingLists({String? familyId});
  
  /// 買い物リストを取得
  Future<ShoppingList?> getShoppingList(String listId);
  
  /// 買い物リストを作成
  Future<String> createShoppingList(ShoppingList shoppingList);
  
  /// 買い物リストを更新
  Future<void> updateShoppingList(ShoppingList shoppingList);
  
  /// 買い物リストを削除
  Future<void> deleteShoppingList(String listId);
  
  /// 買い物リストの商品を取得
  Future<List<ShoppingItem>> getShoppingItems(String listId);
  
  /// 商品を追加
  Future<String> addShoppingItem(ShoppingItem item);
  
  /// 商品を更新
  Future<void> updateShoppingItem(ShoppingItem item);
  
  /// 商品を削除
  Future<void> deleteShoppingItem(String itemId);
  
  /// 商品を完了報告
  Future<void> completeShoppingItem({
    required String itemId,
    required String completedBy,
  });
  
  /// 商品を承認
  Future<void> approveShoppingItem({
    required String itemId,
    required String approvedBy,
  });
  
  /// 商品を拒否
  Future<void> rejectShoppingItem({
    required String itemId,
    required String rejectedBy,
    String? rejectionReason,
  });
  
  /// 承認待ちの商品を取得
  Future<List<ShoppingItem>> getPendingItems({String? familyId});
  
  /// 買い物リストの統計を取得
  Future<Map<String, int>> getShoppingListStats(String listId);
}