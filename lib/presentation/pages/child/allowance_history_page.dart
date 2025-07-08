import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/allowance/allowance_provider.dart';
import '../../../domain/entities/allowance_transaction.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_button.dart';

/// お小遣い履歴ページ
class AllowanceHistoryPage extends ConsumerStatefulWidget {
  const AllowanceHistoryPage({super.key});

  @override
  ConsumerState<AllowanceHistoryPage> createState() => _AllowanceHistoryPageState();
}

class _AllowanceHistoryPageState extends ConsumerState<AllowanceHistoryPage> {
  String _selectedFilter = 'all'; // all, earned, spent

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('お小遣い履歴'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'フィルター',
            onSelected: (filter) => setState(() => _selectedFilter = filter),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('すべて'),
              ),
              const PopupMenuItem(
                value: 'earned',
                child: Text('獲得のみ'),
              ),
              const PopupMenuItem(
                value: 'spent',
                child: Text('使用のみ'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(allowanceProvider.notifier).loadUserAllowanceData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(context, statsAsync),
              const SizedBox(height: 24),
              _buildTransactionsList(context, allowanceState),
            ],
          ),
        ),
      ),
    );
  }

  /// 統計セクション
  Widget _buildStatsSection(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'お小遣い統計',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: '現在の残高',
                      value: '¥${stats['currentBalance']?.toInt() ?? 0}',
                      icon: Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: '今月の獲得',
                      value: '¥${stats['monthlyEarned']?.toInt() ?? 0}',
                      icon: Icons.trending_up,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: '累計獲得',
                      value: '¥${stats['totalEarned']?.toInt() ?? 0}',
                      icon: Icons.savings,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: '累計使用',
                      value: '¥${stats['totalSpent']?.toInt() ?? 0}',
                      icon: Icons.shopping_cart,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (_, __) => const Center(child: Text('統計の読み込みに失敗しました')),
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatCard(
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
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

  /// 取引履歴リスト
  Widget _buildTransactionsList(BuildContext context, AllowanceState state) {
    final filteredTransactions = _filterTransactions(state.transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '取引履歴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_selectedFilter != 'all')
              Chip(
                label: Text(_getFilterDisplayName(_selectedFilter)),
                onDeleted: () => setState(() => _selectedFilter = 'all'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (state.isLoading && state.transactions.isEmpty)
          const Center(child: AppLoadingIndicator())
        else if (state.error != null)
          _buildErrorWidget(context, state.error!)
        else if (filteredTransactions.isEmpty)
          _buildEmptyState(context)
        else
          ...filteredTransactions.map((transaction) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTransactionCard(context, transaction),
          )),
      ],
    );
  }

  /// 取引をフィルタリング
  List<AllowanceTransaction> _filterTransactions(List<AllowanceTransaction> transactions) {
    switch (_selectedFilter) {
      case 'earned':
        return transactions.where((t) => t.type == TransactionType.earned).toList();
      case 'spent':
        return transactions.where((t) => t.type == TransactionType.spent).toList();
      default:
        return transactions;
    }
  }

  /// フィルター表示名を取得
  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'earned':
        return '獲得のみ';
      case 'spent':
        return '使用のみ';
      default:
        return 'すべて';
    }
  }

  /// 取引カード
  Widget _buildTransactionCard(BuildContext context, AllowanceTransaction transaction) {
    final isIncome = transaction.type == TransactionType.earned;
    final color = isIncome 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.add : Icons.remove,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      transaction.type == 'earned' ? '獲得' : '使用',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}¥${transaction.amount.toInt()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '残高: ¥${transaction.balanceAfter.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(transaction.transactionDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              // if (transaction.isToday) ...[  // 一時的に無効化
              //   const SizedBox(width: 8),
              //   Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              //     decoration: BoxDecoration(
              //       color: Theme.of(context).colorScheme.primaryContainer,
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Text(
              //       '今日',
              //       style: Theme.of(context).textTheme.labelSmall?.copyWith(
              //         color: Theme.of(context).colorScheme.primary,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ),
              // ],
            ],
          ),
        ],
      ),
    );
  }

  /// エラーウィジェット
  Widget _buildErrorWidget(BuildContext context, String error) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: '再試行',
            onPressed: () {
              // ref.read(allowanceProvider.notifier).loadUserAllowanceData();
            },
          ),
        ],
      ),
    );
  }

  /// 空状態ウィジェット
  Widget _buildEmptyState(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' 
                ? 'まだ取引履歴がありません'
                : '${_getFilterDisplayName(_selectedFilter)}の履歴がありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'お小遣いを獲得すると履歴が表示されます'
                : 'フィルターを変更して他の履歴を確認してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    
    if (itemDate == today) {
      return '今日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return '昨日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}