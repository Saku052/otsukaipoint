import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../../core/utils/formatters.dart';

/// 買い物商品タイル（リスト表示用）
class ShoppingItemTile extends StatelessWidget {
  /// 買い物商品
  final ShoppingItem shoppingItem;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// チェックボックス変更時のコールバック
  final ValueChanged<bool?>? onCheckChanged;
  
  /// 担当者名
  final String? assigneeName;
  
  /// 完了者名
  final String? completedByName;
  
  /// チェックボックスを表示するかどうか
  final bool showCheckbox;
  
  /// リーディングウィジェット
  final Widget? leading;
  
  /// トレイリングウィジェット
  final Widget? trailing;

  const ShoppingItemTile({
    super.key,
    required this.shoppingItem,
    this.onTap,
    this.onCheckChanged,
    this.assigneeName,
    this.completedByName,
    this.showCheckbox = false,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(context),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dense: false,
    );
  }

  /// リーディングウィジェットを構築
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    
    if (showCheckbox) {
      return Checkbox(
        value: shoppingItem.isCompleted,
        onChanged: shoppingItem.isPending ? onCheckChanged : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    
    return _buildStatusIcon(context);
  }

  /// タイトルを構築
  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            shoppingItem.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: shoppingItem.isApproved 
                  ? TextDecoration.lineThrough 
                  : null,
              color: shoppingItem.isApproved
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildAllowanceChip(context),
      ],
    );
  }

  /// サブタイトルを構築
  Widget? _buildSubtitle(BuildContext context) {
    final subtitleParts = <String>[];
    
    // 説明文
    if (shoppingItem.description != null) {
      subtitleParts.add(shoppingItem.description!);
    }
    
    // 担当者情報
    if (assigneeName != null) {
      subtitleParts.add('担当: $assigneeName');
    }
    
    // 完了者情報
    if (shoppingItem.isCompleted && completedByName != null) {
      final timeAgo = shoppingItem.completedAt != null
          ? Formatters.formatRelativeTime(shoppingItem.completedAt!)
          : '';
      subtitleParts.add('完了: $completedByName $timeAgo');
    }
    
    // 推奨店舗
    if (shoppingItem.suggestedStore != null) {
      subtitleParts.add('店舗: ${shoppingItem.suggestedStore}');
    }
    
    // 予想価格
    if (shoppingItem.estimatedPrice != null) {
      subtitleParts.add(
        '予想: ${Formatters.formatCurrency(shoppingItem.estimatedPrice!)}',
      );
    }
    
    if (subtitleParts.isEmpty) return null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ...subtitleParts.take(2).map((part) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            part,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
    );
  }

  /// トレイリングウィジェットを構築
  Widget? _buildTrailing(BuildContext context) {
    if (trailing != null) return trailing;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatusChip(context),
        if (shoppingItem.completedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            Formatters.formatTime(shoppingItem.completedAt!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
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
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
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

  /// お小遣いチップを構築
  Widget _buildAllowanceChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 2),
          Text(
            Formatters.formatCurrency(shoppingItem.allowanceAmount),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// シンプル商品タイル（チェックリスト用）
class SimpleShoppingItemTile extends StatelessWidget {
  /// 買い物商品
  final ShoppingItem shoppingItem;
  
  /// チェック変更時のコールバック
  final ValueChanged<bool?>? onCheckChanged;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;

  const SimpleShoppingItemTile({
    super.key,
    required this.shoppingItem,
    this.onCheckChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: shoppingItem.isCompleted,
      onChanged: shoppingItem.isPending ? onCheckChanged : null,
      title: Text(
        shoppingItem.name,
        style: TextStyle(
          decoration: shoppingItem.isCompleted 
              ? TextDecoration.lineThrough 
              : null,
        ),
      ),
      subtitle: shoppingItem.allowanceAmount > 0 
          ? Text(
              Formatters.formatCurrency(shoppingItem.allowanceAmount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      secondary: shoppingItem.isCompleted
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }
}