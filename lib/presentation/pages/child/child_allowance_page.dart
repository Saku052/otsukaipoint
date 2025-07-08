import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/allowance/allowance_provider.dart';
import '../../../application/shopping/child_shopping_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_button.dart';

/// 子ども用お小遣い残高ページ
class ChildAllowancePage extends ConsumerStatefulWidget {
  const ChildAllowancePage({super.key});

  @override
  ConsumerState<ChildAllowancePage> createState() => _ChildAllowancePageState();
}

class _ChildAllowancePageState extends ConsumerState<ChildAllowancePage> {
  @override
  void initState() {
    super.initState();
    // Future.microtask(() {
    //   ref.read(allowanceProvider.notifier).loadUserAllowanceData();
    // });
  }

  @override
  Widget build(BuildContext context) {
    final allowanceState = ref.watch(allowanceProvider);
    final statsAsync = ref.watch(allowanceStatsProvider);
    final shoppingStatsAsync = ref.watch(childShoppingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お小遣い残高'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/child/allowance/history'),
            icon: const Icon(Icons.history),
            tooltip: '履歴',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // await ref.read(allowanceProvider.notifier).loadUserAllowanceData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(context, allowanceState, statsAsync),
              const SizedBox(height: 24),
              _buildRecentTransactions(context, allowanceState),
              const SizedBox(height: 24),
              _buildStatsSection(context, shoppingStatsAsync),
              const SizedBox(height: 24),
              _buildActionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 残高カード
  Widget _buildBalanceCard(BuildContext context, allowanceState, AsyncValue<Map<String, dynamic>> statsAsync) {
    return AppCard(
      child: statsAsync.when(
        data: (stats) => Column(
          children: [
            Text(
              '現在の残高',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${stats['currentBalance']?.toInt() ?? 0}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'お疲れさまでした！',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (_, __) => const Center(child: Text('残高の読み込みに失敗しました')),
      ),
    );
  }

  /// 最近の取引
  Widget _buildRecentTransactions(BuildContext context, allowanceState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '最近の取引',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (allowanceState.transactions.isNotEmpty)
              TextButton(
                onPressed: () => context.push('/child/allowance/history'),
                child: const Text('すべて見る'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (allowanceState.isLoading && allowanceState.transactions.isEmpty)
          const Center(child: AppLoadingIndicator())
        else if (allowanceState.transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'まだ取引履歴がありません',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...allowanceState.transactions.take(3).map((transaction) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    transaction.isIncome ? Icons.add : Icons.remove,
                    color: transaction.isIncome 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${transaction.isIncome ? '+' : '-'}¥${transaction.amount.toInt()}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: transaction.isIncome 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  /// アクションセクション
  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アクション',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('取引履歴を見る'),
                subtitle: const Text('お小遣いの獲得・使用履歴を確認'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/child/allowance/history'),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: const Text('ダッシュボードに戻る'),
                subtitle: const Text('お使いリストを確認'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 統計セクション
  Widget _buildStatsSection(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'あなたの成績',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) => Column(
            children: [
              _buildStatItem(
                context,
                title: '完了したお使い',
                value: '${stats['completedItems'] ?? 0}個',
                icon: Icons.check_circle,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              _buildStatItem(
                context,
                title: '承認されたお使い',
                value: '${stats['approvedItems'] ?? 0}個',
                icon: Icons.verified,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _buildStatItem(
                context,
                title: '参加したリスト',
                value: '${stats['totalLists'] ?? 0}個',
                icon: Icons.list_alt,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (_, __) => const Center(child: Text('統計の読み込みに失敗しました')),
        ),
      ],
    );
  }

  /// 統計項目
  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// プレースホルダーセクション
  Widget _buildPlaceholderSection(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '履歴機能は準備中です',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'お小遣いの履歴や使用記録を表示する機能を開発中です',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}