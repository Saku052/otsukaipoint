import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';

/// 子ども用商品カード
class ChildShoppingItemCard extends StatelessWidget {
  /// 商品
  final ShoppingItem shoppingItem;
  
  /// 完了報告コールバック
  final VoidCallback? onComplete;
  
  /// 写真追加コールバック
  final VoidCallback? onAddPhoto;

  const ChildShoppingItemCard({
    super.key,
    required this.shoppingItem,
    this.onComplete,
    this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoppingItem.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (shoppingItem.description != null)
                      Text(
                        shoppingItem.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusChip(context),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 詳細情報
          Row(
            children: [
              if (shoppingItem.estimatedPrice != null) ...[
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '予想価格: ¥${shoppingItem.estimatedPrice!.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'お小遣い: ¥${shoppingItem.allowanceAmount.toInt()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          if (shoppingItem.suggestedStore != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.store,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '推奨店舗: ${shoppingItem.suggestedStore!}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // アクションボタン
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// ステータスに応じたアクションボタンを構築
  Widget _buildActionButtons(BuildContext context) {
    switch (shoppingItem.status) {
      case ItemStatus.pending:
        return Row(
          children: [
            if (onAddPhoto != null)
              Expanded(
                child: AppButton(
                  text: '写真を撮る',
                  type: AppButtonType.outline,
                  size: AppButtonSize.small,
                  icon: Icons.camera_alt,
                  onPressed: onAddPhoto,
                ),
              ),
            if (onAddPhoto != null && onComplete != null)
              const SizedBox(width: 12),
            if (onComplete != null)
              Expanded(
                flex: onAddPhoto != null ? 1 : 2,
                child: AppButton(
                  text: '完了報告',
                  size: AppButtonSize.small,
                  icon: Icons.check,
                  onPressed: onComplete,
                ),
              ),
          ],
        );
        
      case ItemStatus.completed:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '完了報告済み - 承認をお待ちください',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case ItemStatus.approved:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.celebration,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '承認済み！お小遣いをゲットしました',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case ItemStatus.rejected:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '残念！もう一度チャレンジしてみましょう',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  /// ステータスチップを構築
  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor(context);
    final text = _getStatusText();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ステータスに応じた色を取得
  Color _getStatusColor(BuildContext context) {
    switch (shoppingItem.status) {
      case ItemStatus.pending:
        return Theme.of(context).colorScheme.secondary;
      case ItemStatus.completed:
        return Theme.of(context).colorScheme.tertiary;
      case ItemStatus.approved:
        return Theme.of(context).colorScheme.primary;
      case ItemStatus.rejected:
        return Theme.of(context).colorScheme.error;
    }
  }

  /// ステータスに応じたアイコンを取得
  IconData _getStatusIcon() {
    switch (shoppingItem.status) {
      case ItemStatus.pending:
        return Icons.shopping_cart;
      case ItemStatus.completed:
        return Icons.schedule;
      case ItemStatus.approved:
        return Icons.check_circle;
      case ItemStatus.rejected:
        return Icons.error_outline;
    }
  }

  /// ステータスに応じたテキストを取得
  String _getStatusText() {
    switch (shoppingItem.status) {
      case ItemStatus.pending:
        return '待機中';
      case ItemStatus.completed:
        return '報告済み';
      case ItemStatus.approved:
        return '承認済み';
      case ItemStatus.rejected:
        return '要再挑戦';
    }
  }
}