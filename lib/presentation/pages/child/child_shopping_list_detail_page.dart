import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/shopping/child_shopping_provider.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../domain/entities/shopping_list.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/shopping/complete_item_dialog.dart';

/// 子ども用買い物リスト詳細ページ
class ChildShoppingListDetailPage extends ConsumerStatefulWidget {
  /// 買い物リストID
  final String listId;

  const ChildShoppingListDetailPage({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ChildShoppingListDetailPage> createState() => _ChildShoppingListDetailPageState();
}

class _ChildShoppingListDetailPageState extends ConsumerState<ChildShoppingListDetailPage> {
  @override
  void initState() {
    super.initState();
    // ページ読み込み時にリストを取得
    Future.microtask(() {
      ref.read(childShoppingProvider.notifier).loadShoppingListDetail(widget.listId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final childShoppingState = ref.watch(childShoppingProvider);
    final currentUser = ref.watch(currentUserProvider);
    final shoppingList = childShoppingState.selectedList;

    return Scaffold(
      appBar: AppBar(
        title: Text(shoppingList?.title ?? 'お使いリスト'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(childShoppingProvider.notifier).loadShoppingListDetail(widget.listId);
        },
        child: _buildBody(context, childShoppingState, currentUser),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChildShoppingState state, dynamic user) {
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
                ref.read(childShoppingProvider.notifier).loadShoppingListDetail(widget.listId);
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
        description: '指定されたお使いリストが見つかりませんでした',
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
                  label: 'お使いをして',
                  value: 'お小遣いゲット！',
                  icon: Icons.celebration,
                ),
              ),
            ],
          ),
          
          if (shoppingList.deadline != null) ...[ 
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '期限: ${shoppingList.deadline!.month}/${shoppingList.deadline!.day} ${shoppingList.deadline!.hour}:${shoppingList.deadline!.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
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
          size: 32,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 商品リスト
  Widget _buildItemsList(BuildContext context, ShoppingList shoppingList, dynamic user) {
    if (shoppingList.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '商品がありません',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'この買い物リストには商品が登録されていません',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 子供に割り当てられた商品のみフィルタリング
    final assignedItems = shoppingList.items.where((item) => item.assignedTo == user?.id).toList();

    if (assignedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'あなたに割り当てられた商品はありません',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assignedItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = assignedItems[index];
        return _buildShoppingItemCard(context, item, user);
      },
    );
  }

  /// 商品カード
  Widget _buildShoppingItemCard(BuildContext context, ShoppingItem item, dynamic user) {
    final isCompleted = item.status == ItemStatus.completed;
    final isApproved = item.status == ItemStatus.approved;
    final isPending = item.status == ItemStatus.pending;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(context, item.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(item.status),
                  color: _getStatusColor(context, item.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isApproved ? TextDecoration.lineThrough : null,
                        color: isApproved 
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                            : null,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusChip(context, item.status),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 詳細情報
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'お小遣い: ¥${item.allowanceAmount.toInt()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (item.completedAt != null)
                Text(
                  '完了: ${item.completedAt!.month}/${item.completedAt!.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          
          // 完了メモがある場合
          if (item.completionNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.completionNote!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // アクションボタン
          if (isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '完了報告',
                icon: Icons.check_circle,
                onPressed: () => _showCompleteItemDialog(context, item, user),
              ),
            ),
          ] else if (isCompleted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '親の承認待ちです',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isApproved) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '承認済み！お小遣いが付与されました',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ステータスチップ
  Widget _buildStatusChip(BuildContext context, ItemStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context, status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _getStatusColor(context, status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ステータスの色を取得
  Color _getStatusColor(BuildContext context, ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Theme.of(context).colorScheme.outline;
      case ItemStatus.completed:
        return Theme.of(context).colorScheme.tertiary;
      case ItemStatus.approved:
        return Theme.of(context).colorScheme.primary;
      case ItemStatus.rejected:
        return Theme.of(context).colorScheme.error;
    }
  }

  /// ステータスのアイコンを取得
  IconData _getStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Icons.radio_button_unchecked;
      case ItemStatus.completed:
        return Icons.schedule;
      case ItemStatus.approved:
        return Icons.check_circle;
      case ItemStatus.rejected:
        return Icons.cancel;
    }
  }

  /// ステータスのテキストを取得
  String _getStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return '未完了';
      case ItemStatus.completed:
        return '承認待ち';
      case ItemStatus.approved:
        return '承認済み';
      case ItemStatus.rejected:
        return '却下';
    }
  }

  /// 完了報告ダイアログを表示
  void _showCompleteItemDialog(BuildContext context, ShoppingItem item, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => CompleteItemDialog(
        shoppingItem: item,
        onComplete: (photoUrl, note) async {
          final success = await ref.read(childShoppingProvider.notifier).completeShoppingItem(
            item.id,
            user!.id,
            photoUrl: photoUrl,
            note: note,
          );
          
          if (success && mounted) {
            // 成功メッセージは CompleteItemDialog 内で表示される
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('完了報告に失敗しました'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }
}