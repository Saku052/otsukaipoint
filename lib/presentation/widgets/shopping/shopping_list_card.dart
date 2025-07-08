import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_list.dart';
import '../../../core/utils/formatters.dart';
import '../common/app_card.dart';

/// 買い物リストカード
class ShoppingListCard extends StatelessWidget {
  /// 買い物リスト
  final ShoppingList shoppingList;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// メニューボタンのコールバック
  final VoidCallback? onMenuTap;
  
  /// 商品数
  final int itemCount;
  
  /// 完了済み商品数
  final int completedItemCount;
  
  /// 承認済み商品数
  final int approvedItemCount;
  
  /// 総お小遣い金額
  final double totalAllowanceAmount;
  
  /// 獲得済みお小遣い金額
  final double earnedAllowanceAmount;
  
  /// コンパクト表示かどうか
  final bool isCompact;

  const ShoppingListCard({
    super.key,
    required this.shoppingList,
    this.onTap,
    this.onMenuTap,
    required this.itemCount,
    required this.completedItemCount,
    required this.approvedItemCount,
    required this.totalAllowanceAmount,
    required this.earnedAllowanceAmount,
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
          const SizedBox(height: 12),
          _buildProgressSection(context),
          const SizedBox(height: 12),
          _buildFooter(context),
        ],
      ),
    );
  }

  /// コンパクトカードを構築
  Widget _buildCompactCard(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shoppingList.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildCompactInfo(context),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusChip(context),
          if (onMenuTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.more_vert),
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_cart,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shoppingList.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (shoppingList.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  shoppingList.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        _buildStatusChip(context),
        
        if (onMenuTap != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.more_vert),
            iconSize: 20,
          ),
        ],
      ],
    );
  }

  /// 進捗セクションを構築
  Widget _buildProgressSection(BuildContext context) {
    final progressRate = itemCount > 0 ? completedItemCount / itemCount : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '進捗',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$completedItemCount/$itemCount個完了',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressRate,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(context, progressRate),
            ),
          ),
        ),
      ],
    );
  }

  /// フッター部分を構築
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAllowanceInfo(context),
        ),
        if (shoppingList.deadline != null) ...[
          const SizedBox(width: 16),
          _buildDeadlineInfo(context),
        ],
      ],
    );
  }

  /// お小遣い情報を構築
  Widget _buildAllowanceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'お小遣い',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: Formatters.formatCurrency(earnedAllowanceAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              TextSpan(
                text: ' / ${Formatters.formatCurrency(totalAllowanceAmount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 期限情報を構築
  Widget _buildDeadlineInfo(BuildContext context) {
    final deadline = shoppingList.deadline!;
    final isExpired = shoppingList.isExpired;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '期限',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isExpired 
              ? '期限切れ'
              : Formatters.formatRemainingTime(deadline),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isExpired 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// ステータスチップを構築
  Widget _buildStatusChip(BuildContext context) {
    final isCompleted = itemCount > 0 && completedItemCount == itemCount;
    final isApproved = itemCount > 0 && approvedItemCount == itemCount;
    
    String label;
    Color backgroundColor;
    Color textColor;
    
    if (isApproved) {
      label = '完了';
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else if (isCompleted) {
      label = '承認待ち';
      backgroundColor = Theme.of(context).colorScheme.tertiary;
      textColor = Theme.of(context).colorScheme.onTertiary;
    } else if (shoppingList.isExpired) {
      label = '期限切れ';
      backgroundColor = Theme.of(context).colorScheme.error;
      textColor = Theme.of(context).colorScheme.onError;
    } else {
      label = '進行中';
      backgroundColor = Theme.of(context).colorScheme.secondary;
      textColor = Theme.of(context).colorScheme.onSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// コンパクト情報を構築
  Widget _buildCompactInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          '$completedItemCount/$itemCount個',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          Formatters.formatCurrency(totalAllowanceAmount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 進捗バーの色を取得
  Color _getProgressColor(BuildContext context, double progress) {
    if (progress >= 1.0) {
      return Theme.of(context).colorScheme.primary;
    } else if (progress >= 0.5) {
      return Theme.of(context).colorScheme.tertiary;
    } else {
      return Theme.of(context).colorScheme.secondary;
    }
  }
}