import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/shopping/shopping_list_provider.dart';
import '../../../application/approval/approval_provider.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/shopping/shopping_list_card.dart';
import '../debug/debug_log_page.dart';

class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends ConsumerState<ParentDashboardPage> {
  @override
  void initState() {
    super.initState();
    // ページ読み込み時にデータを取得
    Future.microtask(() {
      ref.read(shoppingListProvider.notifier).loadShoppingLists();
      ref.read(approvalProvider.notifier).loadPendingApprovalItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final shoppingListState = ref.watch(shoppingListProvider);
    final approvalState = ref.watch(approvalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('おつかいポイント'),
        elevation: 0,
        actions: [
          // デバッグログボタン
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DebugLogPage(),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => context.push(AppRouter.notifications),
              ),
              if (approvalState.pendingItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      approvalState.pendingItems.length.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRouter.parentSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(shoppingListProvider.notifier).loadShoppingLists(),
            ref.read(approvalProvider.notifier).loadPendingApprovalItems(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context, user),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildPendingApprovalSection(context, approvalState),
              const SizedBox(height: 24),
              _buildRecentShoppingLists(context, shoppingListState),
            ],
          ),
        ),
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

  /// ウェルカムセクション
  Widget _buildWelcomeSection(BuildContext context, dynamic user) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'おかえりなさい！',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.displayName ?? 'ユーザー',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '今日も子どもたちと楽しいお買い物を！',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// クイックアクション
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックアクション',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: 'リスト作成',
                subtitle: '新しい買い物リストを作成',
                icon: Icons.add_shopping_cart,
                onTap: () => context.push(AppRouter.createShoppingList),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'QRコード',
                subtitle: '家族を招待',
                icon: Icons.qr_code,
                onTap: () => context.push(AppRouter.qrCode),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: '承認待ち',
                subtitle: '子どもの報告を確認',
                icon: Icons.pending_actions,
                onTap: () => context.push(AppRouter.approval),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'お小遣い管理',
                subtitle: '残高・履歴を確認',
                icon: Icons.account_balance_wallet,
                onTap: () => context.push(AppRouter.allowanceManagement),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// アクションカード
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 承認待ちセクション
  Widget _buildPendingApprovalSection(BuildContext context, ApprovalState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '承認待ち',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (state.pendingItems.isNotEmpty)
              TextButton(
                onPressed: () => context.push(AppRouter.approval),
                child: const Text('すべて見る'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (state.isLoading)
          const Center(child: AppLoadingIndicator())
        else if (state.pendingItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '承認待ちの商品はありません',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.pendingItems.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
              ),
              title: Text(item.name),
              subtitle: Text('完了報告済み'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _approveItem(item.id),
                    icon: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _rejectItem(item.id),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  /// 最近の買い物リスト
  Widget _buildRecentShoppingLists(BuildContext context, ShoppingListState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '最近の買い物リスト',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.shoppingLists),
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (state.isLoading && state.lists.isEmpty)
          const Center(child: AppLoadingIndicator())
        else if (state.lists.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '買い物リストがありません',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '新しいリストを作成してみましょう',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.lists.take(3).map((shoppingList) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Consumer(
              builder: (context, ref, _) {
                final statsAsync = ref.watch(shoppingListStatsProvider(shoppingList.id));
                
                return statsAsync.when(
                  data: (stats) => ShoppingListCard(
                    shoppingList: shoppingList,
                    itemCount: stats['total'] ?? 0,
                    completedItemCount: stats['completed'] ?? 0,
                    approvedItemCount: stats['approved'] ?? 0,
                    totalAllowanceAmount: 0.0, // TODO: 実際の計算
                    earnedAllowanceAmount: 0.0, // TODO: 実際の計算
                    isCompact: true,
                    onTap: () => context.pushNamed('shoppingListDetail', pathParameters: {'listId': shoppingList.id}),
                  ),
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: AppLoadingIndicator()),
                  ),
                  error: (_, __) => const SizedBox(
                    height: 80,
                    child: Center(child: Text('エラーが発生しました')),
                  ),
                );
              },
            ),
          )),
      ],
    );
  }

  /// 商品を承認
  Future<void> _approveItem(String itemId) async {
    final success = await ref
        .read(approvalProvider.notifier)
        .approveItem(itemId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品を承認しました')),
      );
    }
  }

  /// 商品を拒否
  Future<void> _rejectItem(String itemId) async {
    final success = await ref
        .read(approvalProvider.notifier)
        .rejectItem(itemId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品を拒否しました')),
      );
    }
  }
}