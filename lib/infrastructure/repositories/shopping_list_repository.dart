import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/shopping_item.dart';
import '../../core/errors/exceptions.dart';
import '../services/supabase_service.dart';

/// 買い物リストリポジトリ
class ShoppingListRepository {
  final SupabaseService _supabaseService;

  ShoppingListRepository(this._supabaseService);

  /// 家族の買い物リスト一覧を取得
  Future<List<ShoppingList>> getShoppingLists(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('shopping_lists')
          .select('*')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      return response.map<ShoppingList>((data) {
        return ShoppingList.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: '買い物リストの取得に失敗しました: $e');
    }
  }

  /// 買い物リストを取得（商品含む）
  Future<ShoppingList?> getShoppingListWithItems(String listId) async {
    try {
      print('🔍 買い物リスト詳細取得開始: $listId');

      final response = await _supabaseService.client
          .from('shopping_lists')
          .select('''
            *,
            shopping_items (*)
          ''')
          .eq('id', listId)
          .single();

      print('✅ 買い物リスト詳細取得完了: ${response['title']}');
      print('🔍 詳細取得レスポンス: $response');

      try {
        return ShoppingList.fromMap(response);
      } catch (e) {
        print('❌ 詳細取得時fromMap エラー: $e');
        print('❌ 詳細取得時fromMap エラータイプ: ${e.runtimeType}');
        rethrow;
      }
    } catch (e) {
      print('❌ 買い物リスト詳細取得エラー: $e');
      if (e.toString().contains('PGRST116')) {
        return null; // データが見つからない
      }
      throw ServerException(message: '買い物リストの取得に失敗しました: $e');
    }
  }

  /// 買い物リストを作成
  Future<ShoppingList> createShoppingList({
    required String familyId,
    required String createdBy,
    required String title,
    String? description,
    DateTime? deadline,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      print('🏪 リポジトリ: 買い物リスト作成開始');

      // まず、shopping_listsテーブルの構造を確認
      try {
        final schemaCheck = await _supabaseService.client
            .from('shopping_lists')
            .select('*')
            .limit(1);
        print('📊 shopping_listsテーブル既存データ: $schemaCheck');

        // 最小限のテストデータでスキーマ確認
        final testData = {'title': 'テスト用リスト'};
        print('📊 テストデータ挿入試行: $testData');

        final testInsert = await _supabaseService.client
            .from('shopping_lists')
            .insert(testData)
            .select()
            .single();
        print('📊 テスト挿入成功: $testInsert');

        // テストデータを削除
        await _supabaseService.client
            .from('shopping_lists')
            .delete()
            .eq('id', testInsert['id']);
        print('📊 テストデータ削除完了');
      } catch (schemaError) {
        print('📊 スキーマ確認エラー: $schemaError');
        // エラーの詳細を確認
        print('📊 エラー詳細: ${schemaError.runtimeType}');
        if (schemaError.toString().contains('Could not find')) {
          print('📊 カラムが見つからないエラーです');
        }
      }

      // 一時的にRLSエラーを回避するため、まずダミー家族を確保
      // try {
      //   await _ensureFamilyExists(familyId, createdBy);
      // } catch (e) {
      //   print('⚠️ 家族確保でエラー、続行: $e');
      // }

      // トランザクション開始 - 最小限のフィールドでテスト
      final listData = {
        'family_id': familyId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        // created_at, updated_at は自動生成される可能性があるため除外
      };

      print('📋 挿入データ: $listData');

      final listResponse = await _supabaseService.client
          .from('shopping_lists')
          .insert(listData)
          .select()
          .single();

      print('✅ リスト作成レスポンス: $listResponse');

      final listId = listResponse['id'];

      // 商品追加は一時的に無効化（まずリスト作成のみテスト）
      if (items != null && items.isNotEmpty) {
        print('🛍️ 商品を追加: ${items.length}個');
        final itemsData = items.map((item) {
          return {
            ...item,
            'shopping_list_id': listId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        print('📦 商品データ: $itemsData');

        final response = await _supabaseService.client
            .from('shopping_items')
            .insert(itemsData);

        print('✅ 商品追加レスポンス: $response');

        print('✅ 商品追加完了');
      }

      // 作成されたリストから直接ShoppingListオブジェクトを構築
      print('✅ リスト作成完了、レスポンス使用');
      print('🔍 作成レスポンス詳細: $listResponse');
      print('🔍 作成レスポンスの型: ${listResponse.runtimeType}');
      print('🔍 作成レスポンスのキー: ${listResponse.keys}');

      // レスポンスに必要なフィールドを追加
      final completeListData = {
        ...listResponse,
        'shopping_items': [], // 空のアイテムリスト
      };

      print('🔍 完成データ: $completeListData');

      try {
        return ShoppingList.fromMap(completeListData);
      } catch (e) {
        print('❌ fromMap エラー: $e');
        print('❌ fromMap エラータイプ: ${e.runtimeType}');
        rethrow;
      }
    } catch (e) {
      print('❌ リポジトリエラー: $e');
      print('❌ エラータイプ: ${e.runtimeType}');
      throw ServerException(message: '買い物リストの作成に失敗しました: $e');
    }
  }

  /// 買い物リストを更新
  Future<ShoppingList> updateShoppingList({
    required String listId,
    String? title,
    String? description,
    DateTime? deadline,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      // if (deadline != null) updateData['deadline'] = deadline.toIso8601String(); // 一時的に無効化

      await _supabaseService.client
          .from('shopping_lists')
          .update(updateData)
          .eq('id', listId);

      final updatedList = await getShoppingListWithItems(listId);
      if (updatedList == null) {
        throw ServerException(message: '更新後のリストが見つかりません');
      }
      return updatedList;
    } catch (e) {
      throw ServerException(message: '買い物リストの更新に失敗しました: $e');
    }
  }

  /// 買い物リストを削除
  Future<void> deleteShoppingList(String listId) async {
    try {
      // 関連する商品も自動で削除される（カスケード削除）
      await _supabaseService.client
          .from('shopping_lists')
          .delete()
          .eq('id', listId);
    } catch (e) {
      throw ServerException(message: '買い物リストの削除に失敗しました: $e');
    }
  }

  /// 商品を追加
  Future<ShoppingItem> addShoppingItem({
    required String shoppingListId,
    required String name,
    String? description,
    double? estimatedPrice,
    double allowanceAmount = 0,
    String? assignedTo,
    String? suggestedStore,
  }) async {
    try {
      print('🛍️ 商品追加開始');
      print('📋 リストID: $shoppingListId');
      print('📝 商品名: $name');
      print('💰 お小遣い: $allowanceAmount');
      print('👤 担当者: $assignedTo');

      final itemData = {
        'shopping_list_id': shoppingListId,
        'name': name,
        'description': description,
        'estimated_price': estimatedPrice,
        'allowance_amount': allowanceAmount,
        'assigned_to': assignedTo,
        'suggested_store': suggestedStore, // Supabaseのスキーマキャッシュに存在するため有効化
        'status': ItemStatus.pending.name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📦 送信データ: $itemData');

      final response = await _supabaseService.client
          .from('shopping_items')
          .insert(itemData)
          .select()
          .single();

      print('✅ 商品追加成功: $response');
      return ShoppingItem.fromMap(response);
    } catch (e) {
      print('❌ 商品追加エラー: $e');
      print('❌ エラータイプ: ${e.runtimeType}');
      throw ServerException(message: '商品の追加に失敗しました: $e');
    }
  }

  /// 商品を更新
  Future<ShoppingItem> updateShoppingItem({
    required String itemId,
    String? name,
    String? description,
    double? estimatedPrice,
    double? allowanceAmount,
    String? assignedTo,
    String? suggestedStore,
    ItemStatus? status,
    String? completedBy,
    DateTime? completedAt,
    String? approvedBy,
    DateTime? approvedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (estimatedPrice != null)
        updateData['estimated_price'] = estimatedPrice;
      if (allowanceAmount != null)
        updateData['allowance_amount'] = allowanceAmount;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (suggestedStore != null)
        updateData['suggested_store'] = suggestedStore;
      if (status != null) updateData['status'] = status.name;
      if (completedBy != null) updateData['completed_by'] = completedBy;
      if (completedAt != null)
        updateData['completed_at'] = completedAt.toIso8601String();
      if (approvedBy != null) updateData['approved_by'] = approvedBy;
      if (approvedAt != null)
        updateData['approved_at'] = approvedAt.toIso8601String();

      final response = await _supabaseService.client
          .from('shopping_items')
          .update(updateData)
          .eq('id', itemId)
          .select()
          .single();

      return ShoppingItem.fromMap(response);
    } catch (e) {
      throw ServerException(message: '商品の更新に失敗しました: $e');
    }
  }

  /// 商品を完了報告
  Future<ShoppingItem> completeShoppingItem({
    required String itemId,
    required String completedBy,
    String? photoUrl,
    String? note,
  }) async {
    final updateData = <String, dynamic>{
      'status': ItemStatus.completed.name,
      'completed_by': completedBy,
      'completed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (photoUrl != null) updateData['photo_url'] = photoUrl;
    if (note != null) updateData['completion_note'] = note;

    try {
      final response = await _supabaseService.client
          .from('shopping_items')
          .update(updateData)
          .eq('id', itemId)
          .select()
          .single();

      return ShoppingItem.fromMap(response);
    } catch (e) {
      throw ServerException(message: '商品の完了報告に失敗しました: $e');
    }
  }

  /// 商品を承認
  Future<ShoppingItem> approveShoppingItem({
    required String itemId,
    required String approvedBy,
  }) async {
    return updateShoppingItem(
      itemId: itemId,
      status: ItemStatus.approved,
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
    );
  }

  /// 商品を拒否
  Future<ShoppingItem> rejectShoppingItem({
    required String itemId,
    required String rejectedBy,
  }) async {
    return updateShoppingItem(
      itemId: itemId,
      status: ItemStatus.rejected,
      approvedBy: rejectedBy,
      approvedAt: DateTime.now(),
    );
  }

  /// 商品を削除
  Future<void> deleteShoppingItem(String itemId) async {
    try {
      await _supabaseService.client
          .from('shopping_items')
          .delete()
          .eq('id', itemId);
    } catch (e) {
      throw ServerException(message: '商品の削除に失敗しました: $e');
    }
  }

  /// 子供の買い物リスト一覧を取得（割り当てられたもののみ）
  Future<List<ShoppingList>> getAssignedShoppingLists(String childId) async {
    try {
      final response = await _supabaseService.client
          .from('shopping_lists')
          .select('''
            *,
            shopping_items!inner(*)
          ''')
          .eq('shopping_items.assigned_to', childId)
          .order('created_at', ascending: false);

      return response.map<ShoppingList>((data) {
        return ShoppingList.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: '割り当てられた買い物リストの取得に失敗しました: $e');
    }
  }

  /// 承認待ちの商品一覧を取得
  Future<List<ShoppingItem>> getPendingApprovalItems(String familyId) async {
    try {
      final response = await _supabaseService.client
          .from('shopping_items')
          .select('''
            *,
            shopping_list:shopping_lists!inner(title, family_id)
          ''')
          .eq('status', ItemStatus.completed.name)
          .eq('shopping_list.family_id', familyId)
          .order('completed_at', ascending: false);

      return response.map<ShoppingItem>((data) {
        return ShoppingItem.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: '承認待ち商品の取得に失敗しました: $e');
    }
  }

  /// 商品の統計を取得
  Future<Map<String, int>> getShoppingItemStats(String listId) async {
    try {
      print('📊 統計取得開始: $listId');
      
      final response = await _supabaseService.client
          .from('shopping_items')
          .select('status')
          .eq('shopping_list_id', listId);

      print('📊 統計取得結果: ${response.length}件');

      final stats = <String, int>{
        'total': response.length,
        'pending': 0,
        'completed': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final item in response) {
        final status = item['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      print('📊 統計結果: $stats');
      return stats;
    } catch (e) {
      print('❌ 統計取得エラー: $e');
      throw ServerException(message: '商品統計の取得に失敗しました: $e');
    }
  }

  /// IDで買い物リストを取得
  Future<ShoppingList?> getShoppingListById(String listId) async {
    return getShoppingListWithItems(listId);
  }

  /// 家族とメンバーの存在を確保（RLSエラー回避用）
  Future<void> _ensureFamilyExists(String familyId, String userId) async {
    try {
      print('👨‍👩‍👧‍👦 家族存在確認: $familyId');

      // 家族が存在するかチェック
      final familyExists = await _supabaseService.client
          .from('families')
          .select('id')
          .eq('id', familyId)
          .maybeSingle();

      if (familyExists == null) {
        print('🏠 家族が存在しないため作成: $familyId');
        // 家族を作成
        await _supabaseService.client.from('families').insert({
          'id': familyId,
          'name': 'デフォルト家族',
          'invite_code': DateTime.now().millisecondsSinceEpoch
              .toString()
              .substring(7), // 6桁の招待コード
          'created_by': userId,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // ユーザーが家族メンバーに存在するかチェック
      final memberExists = await _supabaseService.client
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberExists == null) {
        print('👤 家族メンバーが存在しないため追加: $userId');
        // メンバーを追加
        await _supabaseService.client.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'parent',
          'is_active': true,
          'joined_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      print('✅ 家族とメンバーの存在確認完了');
    } catch (e) {
      print('⚠️ 家族作成エラー (続行): $e');
      // エラーが発生しても続行（既に存在している可能性があるため）
    }
  }
}

/// 買い物リストリポジトリプロバイダー
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  return ShoppingListRepository(supabaseService);
});
