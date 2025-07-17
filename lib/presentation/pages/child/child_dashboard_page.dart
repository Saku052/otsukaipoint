import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/shopping/child_shopping_provider.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/shopping/shopping_list_card.dart';

/// 子どもダッシュボードページ
class ChildDashboardPage extends ConsumerStatefulWidget {
  const ChildDashboardPage({super.key});

  @override
  ConsumerState<ChildDashboardPage> createState() => _ChildDashboardPageState();
}

class _ChildDashboardPageState extends ConsumerState<ChildDashboardPage> {
  @override
  void initState() {
    super.initState();
    // ページ読み込み時にデータを取得
    Future.microtask(() {
      ref.read(childShoppingProvider.notifier).loadAssignedShoppingLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final childShoppingState = ref.watch(childShoppingProvider);
    final statsAsync = ref.watch(childShoppingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('おつかいポイント'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push(AppRouter.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRouter.childSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(childShoppingProvider.notifier).loadAssignedShoppingLists();
          ref.refresh(childShoppingStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context, user),
              const SizedBox(height: 24),
              _buildStatsSection(context, statsAsync),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildActiveShoppingLists(context, childShoppingState),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQRScanner(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'QR\nスキャン',
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
              Icons.child_care,
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
                  '今日のお使いを頑張りましょう！',
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

  /// 統計セクション
  Widget _buildStatsSection(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'あなたの進捗',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) => _buildStatsCards(context, stats),
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (_, __) => const Center(child: Text('統計の読み込みに失敗しました')),
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatsCards(BuildContext context, Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'リスト数',
            value: '${stats['totalLists'] ?? 0}',
            subtitle: '個',
            icon: Icons.list_alt,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            title: '完了商品',
            value: '${stats['completedItems'] ?? 0}',
            subtitle: '個',
            icon: Icons.check_circle,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            title: '獲得ポイント',
            value: '¥${stats['totalEarnings'] ?? 0}',
            subtitle: '',
            icon: Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
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
                title: 'QRスキャン',
                subtitle: '新しいリストを取得',
                icon: Icons.qr_code_scanner,
                onTap: () => _showQRScanner(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'お小遣い残高',
                subtitle: '残高を確認',
                icon: Icons.account_balance_wallet,
                onTap: () => context.push(AppRouter.allowanceBalance),
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

  /// アクティブな買い物リスト
  Widget _buildActiveShoppingLists(BuildContext context, ChildShoppingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'あなたのお使いリスト',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (state.assignedLists.isNotEmpty)
              TextButton(
                onPressed: () => context.push(AppRouter.childShoppingLists),
                child: const Text('すべて見る'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (state.isLoading && state.assignedLists.isEmpty)
          const Center(child: AppLoadingIndicator())
        else if (state.error != null)
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (state.assignedLists.isEmpty)
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
                    'お使いリストがありません',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QRコードをスキャンして新しいリストを追加しましょう',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.assignedLists.take(3).map((shoppingList) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShoppingListCard(
              shoppingList: shoppingList,
              itemCount: 0, // TODO: 実際の商品数
              completedItemCount: 0, // TODO: 完了商品数
              approvedItemCount: 0, // TODO: 承認商品数
              totalAllowanceAmount: 0.0, // TODO: 総お小遣い
              earnedAllowanceAmount: 0.0, // TODO: 獲得お小遣い
              isCompact: true,
              onTap: () => _navigateToShoppingListDetail(shoppingList.id),
            ),
          )),
      ],
    );
  }

  /// 買い物リスト詳細に遷移
  void _navigateToShoppingListDetail(String listId) {
    context.push('${AppRouter.childShoppingListDetail}/$listId');
  }

  /// QRスキャナーを表示
  void _showQRScanner(BuildContext context) {
    context.push(AppRouter.qrScanner);
  }
}