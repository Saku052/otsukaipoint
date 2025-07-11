import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/shopping/shopping_list_provider.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/shopping_list.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/shopping/shopping_item_card.dart';
import '../../widgets/shopping/add_item_dialog.dart';

/// 買い物リスト詳細ページ
class ShoppingListDetailPage extends ConsumerStatefulWidget {
  /// 買い物リストID
  final String listId;

  const ShoppingListDetailPage({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ShoppingListDetailPage> createState() => _ShoppingListDetailPageState();
}

class _ShoppingListDetailPageState extends ConsumerState<ShoppingListDetailPage> {
  @override
  void initState() {
    super.initState();
    print('📄 ShoppingListDetailPage 初期化: ${widget.listId}');
    // ページ読み込み時にリストを取得
    Future.microtask(() {
      print('🔄 買い物リスト詳細読み込み開始: ${widget.listId}');
      ref.read(shoppingListProvider.notifier).loadShoppingList(widget.listId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListState = ref.watch(shoppingListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final shoppingList = shoppingListState.selectedList;

    return Scaffold(
      appBar: AppBar(
        title: Text(shoppingList?.title ?? '買い物リスト'),
        elevation: 0,
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
          if (shoppingList != null) ...[
            IconButton(
              onPressed: () => _showListMenu(context, shoppingList),
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(shoppingListProvider.notifier).loadShoppingList(widget.listId);
        },
        child: _buildBody(context, shoppingListState, currentUser),
      ),
      floatingActionButton: shoppingList != null
          ? FloatingActionButton(
              onPressed: () => _addShoppingItem(context, shoppingList),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, ShoppingListState state, dynamic user) {
    if (state.isLoading && state.selectedList == null) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                ref.read(shoppingListProvider.notifier).loadShoppingList(widget.listId);
              },
            ),
          ],
        ),
      );
    }

    final shoppingList = state.selectedList;
    if (shoppingList == null) {
      return const AppEmptyStateWidget(
        title: 'リストが見つかりません',
        description: '指定された買い物リストが見つかりませんでした',
        icon: Icons.search_off,
      );
    }

    return Column(
      children: [
        _buildListHeader(context, shoppingList),
        Expanded(
          child: _buildItemsList(context, shoppingList, user),
        ),
      ],
    );
  }

  /// リストヘッダー
  Widget _buildListHeader(BuildContext context, ShoppingList shoppingList) {
    final totalItems = shoppingList.items.length;
    final completedItems = shoppingList.items.where((item) => item.isCompleted).length;
    final approvedItems = shoppingList.items.where((item) => item.isApproved).length;
    final totalAllowance = shoppingList.items.fold<double>(
      0, 
      (sum, item) => sum + item.allowanceAmount,
    );
    final earnedAllowance = shoppingList.items
        .where((item) => item.isApproved)
        .fold<double>(0, (sum, item) => sum + item.allowanceAmount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shoppingList.description != null) ...[
            Text(
              shoppingList.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 進捗情報
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '商品数',
                  value: '$totalItems個',
                  icon: Icons.shopping_cart,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '完了',
                  value: '$completedItems個',
                  icon: Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '承認済み',
                  value: '$approvedItems個',
                  icon: Icons.verified,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // お小遣い情報
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '総お小遣い',
                  value: '¥${totalAllowance.toInt()}',
                  icon: Icons.account_balance_wallet,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: '獲得済み',
                  value: '¥${earnedAllowance.toInt()}',
                  icon: Icons.savings,
                ),
              ),
            ],
          ),
          
          // 期限表示は一時的に無効化（DBカラムが存在しないため）
          // if (shoppingList.deadline != null) ...[
          //   const SizedBox(height: 16),
          //   Row(
          //     children: [
          //       Icon(
          //         Icons.schedule,
          //         size: 16,
          //         color: Theme.of(context).colorScheme.onPrimaryContainer,
          //       ),
          //       const SizedBox(width: 8),
          //       Text(
          //         '期限: ${shoppingList.deadline!.month}/${shoppingList.deadline!.day} ${shoppingList.deadline!.hour}:${shoppingList.deadline!.minute.toString().padLeft(2, '0')}',
          //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //           color: Theme.of(context).colorScheme.onPrimaryContainer,
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
        ],
      ),
    );
  }

  /// 統計項目
  Widget _buildStatItem(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// 商品リスト
  Widget _buildItemsList(BuildContext context, ShoppingList shoppingList, dynamic user) {
    if (shoppingList.items.isEmpty) {
      return const AppEmptyStateWidget.shoppingItems(
        title: '商品がありません',
        description: '商品を追加して買い物を始めましょう',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: shoppingList.items.length,
      itemBuilder: (context, index) {
        final item = shoppingList.items[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShoppingItemCard(
            shoppingItem: item,
            isParentView: true, // 親の視点
            onApprove: item.isPendingApproval ? () => _approveItem(item) : null,
            onReject: item.isPendingApproval ? () => _rejectItem(item) : null,
            onMenuTap: () => _showItemMenu(context, item),
          ),
        );
      },
    );
  }

  /// リストメニューを表示
  void _showListMenu(BuildContext context, ShoppingList shoppingList) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('リストを編集'),
              onTap: () {
                Navigator.pop(context);
                _editShoppingList(context, shoppingList);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('リストを削除'),
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

  /// アイテムメニューを表示
  void _showItemMenu(BuildContext context, ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('商品を編集'),
              onTap: () {
                Navigator.pop(context);
                _editShoppingItem(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('商品を削除'),
              onTap: () {
                Navigator.pop(context);
                _deleteShoppingItem(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 商品を追加
  void _addShoppingItem(BuildContext context, ShoppingList shoppingList) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        shoppingListId: shoppingList.id,
      ),
    );
  }

  /// 買い物リストを編集
  void _editShoppingList(BuildContext context, ShoppingList shoppingList) {
    // TODO: リスト編集ダイアログを表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('リスト編集機能は準備中です')),
    );
  }

  /// 買い物リストを削除
  void _deleteShoppingList(BuildContext context, ShoppingList shoppingList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リストを削除'),
        content: const Text('この買い物リストを削除してもよろしいですか？\nこの操作は取り消せません。'),
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
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('買い物リストを削除しました')),
                );
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 商品を編集
  void _editShoppingItem(BuildContext context, ShoppingItem item) {
    // TODO: 商品編集ダイアログを表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('商品編集機能は準備中です')),
    );
  }

  /// 商品を削除
  void _deleteShoppingItem(BuildContext context, ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('商品を削除'),
        content: Text('「${item.name}」を削除してもよろしいですか？'),
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
                  .deleteShoppingItem(item.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('商品を削除しました')),
                );
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 商品を承認
  Future<void> _approveItem(ShoppingItem item) async {
    final success = await ref
        .read(shoppingListProvider.notifier)
        .approveShoppingItem(item.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${item.name}」を承認しました')),
      );
    }
  }

  /// 商品を拒否
  Future<void> _rejectItem(ShoppingItem item) async {
    final success = await ref
        .read(shoppingListProvider.notifier)
        .rejectShoppingItem(item.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${item.name}」を拒否しました')),
      );
    }
  }
}