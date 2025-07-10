import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/shopping/shopping_list_provider.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/shopping/shopping_list_card.dart';

/// 買い物リスト一覧ページ（親用）
class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ページ読み込み時にリスト一覧を取得
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // アプリがフォアグラウンドに復帰した時にデータを更新
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が再表示された時にデータを更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  /// データを更新
  void _refreshData() {
    Future.microtask(() {
      ref.read(shoppingListProvider.notifier).loadShoppingLists();
      // 統計プロバイダーはautoDisposeなので自動的にリフレッシュされる
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final shoppingListState = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト'),
        elevation: 0,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRouter.parentDashboard),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            tooltip: 'ホームに戻る',
          ),
          IconButton(
            onPressed: () => _showFilterMenu(context),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 統計プロバイダーはautoDisposeなので自動的にリフレッシュされる
          await ref.read(shoppingListProvider.notifier).loadShoppingLists();
        },
        child: _buildBody(context, shoppingListState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.createShoppingList),
        label: const Text(
          'リスト\n作成',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ShoppingListState state) {
    if (state.isLoading && state.lists.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: '再試行',
              onPressed: () {
                ref.read(shoppingListProvider.notifier).loadShoppingLists();
              },
            ),
          ],
        ),
      );
    }

    if (state.lists.isEmpty) {
      return const AppEmptyStateWidget.shoppingList(
        title: '買い物リストがありません',
        description: '新しい買い物リストを作成してお使いを始めましょう',
      );
    }

    return Column(
      children: [
        if (state.isLoading)
          Container(
            height: 4,
            child: const LinearProgressIndicator(),
          ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.lists.length,
            itemBuilder: (context, index) {
              final shoppingList = state.lists[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Consumer(
                  builder: (context, ref, _) {
                    // 各リストの統計を取得
                    final statsAsync = ref.watch(shoppingListStatsProvider(shoppingList.id));
                    
                    return statsAsync.when(
                      data: (stats) {
                        return ShoppingListCard(
                          shoppingList: shoppingList,
                          itemCount: stats['total'] ?? 0,
                          completedItemCount: stats['completed'] ?? 0,
                          approvedItemCount: stats['approved'] ?? 0,
                          totalAllowanceAmount: _calculateTotalAllowance(shoppingList),
                          earnedAllowanceAmount: _calculateEarnedAllowance(shoppingList),
                          onTap: () => _navigateToDetail(shoppingList.id),
                          onMenuTap: () => _showListMenu(context, shoppingList),
                        );
                      },
                      loading: () => _buildLoadingCard(shoppingList),
                      error: (_, __) => _buildErrorCard(shoppingList),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ローディング中のカード
  Widget _buildLoadingCard(dynamic shoppingList) {
    return ShoppingListCard(
      shoppingList: shoppingList,
      itemCount: 0,
      completedItemCount: 0,
      approvedItemCount: 0,
      totalAllowanceAmount: 0.0,
      earnedAllowanceAmount: 0.0,
      onTap: () => _navigateToDetail(shoppingList.id),
    );
  }

  /// エラー時のカード
  Widget _buildErrorCard(dynamic shoppingList) {
    return ShoppingListCard(
      shoppingList: shoppingList,
      itemCount: 0,
      completedItemCount: 0,
      approvedItemCount: 0,
      totalAllowanceAmount: 0.0,
      earnedAllowanceAmount: 0.0,
      onTap: () => _navigateToDetail(shoppingList.id),
      onMenuTap: () => _showListMenu(context, shoppingList),
    );
  }

  /// 総お小遣い金額を計算（実際の実装では統計から取得）
  double _calculateTotalAllowance(dynamic shoppingList) {
    // TODO: 実際の統計データから計算
    return 0.0;
  }

  /// 獲得済みお小遣い金額を計算（実際の実装では統計から取得）
  double _calculateEarnedAllowance(dynamic shoppingList) {
    // TODO: 実際の統計データから計算
    return 0.0;
  }

  /// 詳細ページに遷移
  void _navigateToDetail(String listId) {
    context.pushNamed('shoppingListDetail', pathParameters: {'listId': listId});
  }

  /// フィルターメニューを表示
  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'フィルター',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('すべて'),
              onTap: () {
                Navigator.pop(context);
                // すべて表示
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('進行中'),
              onTap: () {
                Navigator.pop(context);
                // 進行中のみ表示
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('完了済み'),
              onTap: () {
                Navigator.pop(context);
                // 完了済みのみ表示
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('期限間近'),
              onTap: () {
                Navigator.pop(context);
                // 期限間近のみ表示
              },
            ),
          ],
        ),
      ),
    );
  }

  /// リストメニューを表示
  void _showListMenu(BuildContext context, dynamic shoppingList) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('詳細を見る'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(shoppingList.id);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                _editShoppingList(context, shoppingList);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('共有'),
              onTap: () {
                Navigator.pop(context);
                _shareShoppingList(context, shoppingList);
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '削除',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteShoppingList(context, shoppingList);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 買い物リストを編集
  void _editShoppingList(BuildContext context, dynamic shoppingList) {
    // TODO: 編集ページに遷移
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('編集機能は準備中です')),
    );
  }

  /// 買い物リストを共有
  void _shareShoppingList(BuildContext context, dynamic shoppingList) {
    // TODO: 共有機能を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('共有機能は準備中です')),
    );
  }

  /// 買い物リストを削除
  void _deleteShoppingList(BuildContext context, dynamic shoppingList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リストを削除'),
        content: Text('「${shoppingList.title}」を削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await ref
                  .read(shoppingListProvider.notifier)
                  .deleteShoppingList(shoppingList.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('買い物リストを削除しました')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}