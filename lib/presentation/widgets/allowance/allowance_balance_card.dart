import 'package:flutter/material.dart';
import '../../../domain/entities/allowance_balance.dart';
import '../../../core/utils/formatters.dart';
import '../common/app_card.dart';

/// お小遣い残高カード
class AllowanceBalanceCard extends StatelessWidget {
  /// お小遣い残高情報
  final AllowanceBalance balance;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// 履歴を表示するコールバック
  final VoidCallback? onViewHistory;
  
  /// お小遣いを使用するコールバック
  final VoidCallback? onUseAllowance;
  
  /// 親の視点かどうか
  final bool isParentView;
  
  /// コンパクト表示かどうか
  final bool isCompact;

  const AllowanceBalanceCard({
    super.key,
    required this.balance,
    this.onTap,
    this.onViewHistory,
    this.onUseAllowance,
    this.isParentView = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  /// フルサイズカードを構築
  Widget _buildFullCard(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildBalanceInfo(context),
          const SizedBox(height: 16),
          _buildStats(context),
          if (_shouldShowActions()) ...[
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  /// コンパクトカードを構築
  Widget _buildCompactCard(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'お小遣い残高',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatCurrency(balance.balance),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (onViewHistory != null)
            IconButton(
              onPressed: onViewHistory,
              icon: const Icon(Icons.history),
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.secondary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'お小遣い残高',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '最終更新: ${Formatters.formatRelativeTime(balance.lastUpdated)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 残高情報を構築
  Widget _buildBalanceInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '現在の残高',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(balance.balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報を構築
  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            label: '今月獲得',
            value: Formatters.formatCurrency(0.0),
            icon: Icons.trending_up,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            context,
            label: '今月利用',
            value: Formatters.formatCurrency(0.0),
            icon: Icons.trending_down,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  /// 統計項目を構築
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// アクション部分を構築
  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];
    
    if (onViewHistory != null) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewHistory,
            icon: const Icon(Icons.history),
            label: const Text('履歴を見る'),
          ),
        ),
      );
    }
    
    if (onUseAllowance != null && !isParentView) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 8));
      }
      actions.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: onUseAllowance,
            icon: const Icon(Icons.shopping_cart),
            label: const Text('使用する'),
          ),
        ),
      );
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    
    return Row(children: actions);
  }

  /// アクションを表示すべきかどうかを判定
  bool _shouldShowActions() {
    return onViewHistory != null || (onUseAllowance != null && !isParentView);
  }
}