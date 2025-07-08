import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../../core/utils/formatters.dart';
import '../common/app_card.dart';

/// 買い物商品カード
class ShoppingItemCard extends StatelessWidget {
  /// 買い物商品
  final ShoppingItem shoppingItem;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// 完了ボタンのコールバック
  final VoidCallback? onComplete;
  
  /// 承認ボタンのコールバック
  final VoidCallback? onApprove;
  
  /// 拒否ボタンのコールバック
  final VoidCallback? onReject;
  
  /// メニューボタンのコールバック
  final VoidCallback? onMenuTap;
  
  /// 担当者名
  final String? assigneeName;
  
  /// 完了者名
  final String? completedByName;
  
  /// 承認者名
  final String? approvedByName;
  
  /// 親の視点かどうか
  final bool isParentView;

  const ShoppingItemCard({
    super.key,
    required this.shoppingItem,
    this.onTap,
    this.onComplete,
    this.onApprove,
    this.onReject,
    this.onMenuTap,
    this.assigneeName,
    this.completedByName,
    this.approvedByName,
    this.isParentView = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildContent(context),
          const SizedBox(height: 12),
          _buildFooter(context),
          if (_shouldShowActions()) ...[
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildStatusIcon(context),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            shoppingItem.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              decoration: shoppingItem.isApproved ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

  /// コンテンツ部分を構築
  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shoppingItem.description != null) ...[
          Text(
            shoppingItem.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        
        Row(
          children: [
            if (shoppingItem.estimatedPrice != null) ...[
              _buildInfoChip(
                context,
                icon: Icons.price_check,
                label: '予想価格',
                value: Formatters.formatCurrency(shoppingItem.estimatedPrice!),
              ),
              const SizedBox(width: 8),
            ],
            
            _buildInfoChip(
              context,
              icon: Icons.account_balance_wallet,
              label: 'お小遣い',
              value: Formatters.formatCurrency(shoppingItem.allowanceAmount),
              isHighlight: true,
            ),
          ],
        ),
        
        if (shoppingItem.suggestedStore != null) ...[
          const SizedBox(height: 8),
          _buildInfoChip(
            context,
            icon: Icons.store,
            label: '推奨店舗',
            value: shoppingItem.suggestedStore!,
          ),
        ],
      ],
    );
  }

  /// フッター部分を構築
  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assigneeName != null) ...[
          _buildPersonInfo(
            context,
            icon: Icons.person_outline,
            label: '担当者',
            name: assigneeName!,
          ),
        ],
        
        if (shoppingItem.isCompleted && completedByName != null) ...[
          if (assigneeName != null) const SizedBox(height: 4),
          _buildPersonInfo(
            context,
            icon: Icons.check_circle_outline,
            label: '完了者',
            name: completedByName!,
            timestamp: shoppingItem.completedAt,
          ),
        ],
        
        if (shoppingItem.isApproved && approvedByName != null) ...[
          const SizedBox(height: 4),
          _buildPersonInfo(
            context,
            icon: shoppingItem.isApproved 
                ? Icons.thumb_up_outlined 
                : Icons.thumb_down_outlined,
            label: shoppingItem.isApproved ? '承認者' : '拒否者',
            name: approvedByName!,
            timestamp: shoppingItem.approvedAt,
          ),
        ],
      ],
    );
  }

  /// アクション部分を構築
  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];
    
    if (shoppingItem.isPending && onComplete != null) {
      actions.add(
        Expanded(
          child: FilledButton(
            onPressed: onComplete,
            child: const Text('完了報告'),
          ),
        ),
      );
    }
    
    if (shoppingItem.isPendingApproval && isParentView) {
      if (onApprove != null) {
        actions.add(
          Expanded(
            child: FilledButton(
              onPressed: onApprove,
              child: const Text('承認'),
            ),
          ),
        );
      }
      
      if (onReject != null) {
        if (actions.isNotEmpty) {
          actions.add(const SizedBox(width: 8));
        }
        actions.add(
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              child: const Text('拒否'),
            ),
          ),
        );
      }
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    
    return Row(children: actions);
  }

  /// ステータスアイコンを構築
  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (shoppingItem.status) {
      case ItemStatus.pending:
        icon = Icons.radio_button_unchecked;
        color = Theme.of(context).colorScheme.outline;
        break;
      case ItemStatus.completed:
        icon = Icons.schedule;
        color = Theme.of(context).colorScheme.tertiary;
        break;
      case ItemStatus.approved:
        icon = Icons.check_circle;
        color = Theme.of(context).colorScheme.primary;
        break;
      case ItemStatus.rejected:
        icon = Icons.cancel;
        color = Theme.of(context).colorScheme.error;
        break;
    }
    
    return Icon(icon, color: color, size: 24);
  }

  /// ステータスチップを構築
  Widget _buildStatusChip(BuildContext context) {
    final status = shoppingItem.status;
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case ItemStatus.pending:
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        textColor = Theme.of(context).colorScheme.onSecondaryContainer;
        break;
      case ItemStatus.completed:
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        textColor = Theme.of(context).colorScheme.onTertiaryContainer;
        break;
      case ItemStatus.approved:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        textColor = Theme.of(context).colorScheme.onPrimaryContainer;
        break;
      case ItemStatus.rejected:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        textColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 情報チップを構築
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isHighlight
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isHighlight
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: isHighlight ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 人物情報を構築
  Widget _buildPersonInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String name,
    DateTime? timestamp,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (timestamp != null) ...[
          const SizedBox(width: 8),
          Text(
            '(${Formatters.formatRelativeTime(timestamp)})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  /// アクションを表示すべきかどうかを判定
  bool _shouldShowActions() {
    return (shoppingItem.isPending && onComplete != null) ||
           (shoppingItem.isPendingApproval && isParentView && (onApprove != null || onReject != null));
  }
}