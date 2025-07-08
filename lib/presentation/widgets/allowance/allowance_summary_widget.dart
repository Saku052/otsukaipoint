import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';

/// お小遣い概要ウィジェット
class AllowanceSummaryWidget extends StatelessWidget {
  /// 現在の残高
  final double currentBalance;
  
  /// 今月の獲得額
  final double monthlyEarned;
  
  /// 今月の使用額
  final double monthlySpent;
  
  /// 先月の獲得額
  final double lastMonthEarned;
  
  /// 子供の名前
  final String? childName;
  
  /// 詳細を表示するコールバック
  final VoidCallback? onShowDetails;

  const AllowanceSummaryWidget({
    super.key,
    required this.currentBalance,
    required this.monthlyEarned,
    required this.monthlySpent,
    required this.lastMonthEarned,
    this.childName,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildBalanceSection(context),
            const SizedBox(height: 16),
            _buildStatsSection(context),
            if (onShowDetails != null) ...[
              const SizedBox(height: 16),
              _buildDetailsButton(context),
            ],
          ],
        ),
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.account_balance_wallet,
          color: Theme.of(context).colorScheme.secondary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            childName != null ? '$childNameのお小遣い' : 'お小遣い概要',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// 残高セクションを構築
  Widget _buildBalanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '現在の残高',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(currentBalance),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  /// 統計セクションを構築
  Widget _buildStatsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                label: '今月獲得',
                value: monthlyEarned,
                icon: Icons.trending_up,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                context,
                label: '今月使用',
                value: monthlySpent,
                icon: Icons.trending_down,
                isPositive: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildComparisonSection(context),
      ],
    );
  }

  /// 統計項目を構築
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required double value,
    required IconData icon,
    required bool isPositive,
  }) {
    final color = isPositive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatCurrency(value),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 比較セクションを構築
  Widget _buildComparisonSection(BuildContext context) {
    final monthlyChange = monthlyEarned - lastMonthEarned;
    final isIncrease = monthlyChange > 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncrease
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '先月比較',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${isIncrease ? '+' : ''}${Formatters.formatCurrency(monthlyChange)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isIncrease
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '先月: ${Formatters.formatCurrency(lastMonthEarned)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細ボタンを構築
  Widget _buildDetailsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onShowDetails,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          side: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        child: const Text('詳細を見る'),
      ),
    );
  }
}

/// シンプルなお小遣い表示ウィジェット
class SimpleAllowanceWidget extends StatelessWidget {
  /// 残高
  final double balance;
  
  /// ラベル
  final String label;
  
  /// アイコン
  final IconData? icon;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;

  const SimpleAllowanceWidget({
    super.key,
    required this.balance,
    this.label = 'お小遣い',
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatCurrency(balance),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}