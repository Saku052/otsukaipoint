import 'package:flutter/material.dart';
import '../../../domain/entities/allowance_transaction.dart';
import '../../../core/utils/formatters.dart';

/// お小遣い取引タイル
class AllowanceTransactionTile extends StatelessWidget {
  /// お小遣い取引情報
  final AllowanceTransaction transaction;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// 詳細を表示するコールバック
  final VoidCallback? onShowDetails;
  
  /// コンパクト表示かどうか
  final bool isCompact;

  const AllowanceTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onShowDetails,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactTile(context);
    }
    return _buildFullTile(context);
  }

  /// フルサイズタイルを構築
  Widget _buildFullTile(BuildContext context) {
    return ListTile(
      leading: _buildIcon(context),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// コンパクトタイルを構築
  Widget _buildCompactTile(BuildContext context) {
    return ListTile(
      leading: _buildIcon(context),
      title: Text(
        transaction.description,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildAmountText(context),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }

  /// アイコンを構築
  Widget _buildIcon(BuildContext context) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;
    
    switch (transaction.type) {
      case TransactionType.earned:
        iconData = Icons.add_circle;
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case TransactionType.spent:
        iconData = Icons.remove_circle;
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        iconColor = Theme.of(context).colorScheme.error;
        break;
      case TransactionType.bonus:
        iconData = Icons.star;
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      case TransactionType.penalty:
        iconData = Icons.warning;
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        iconColor = Theme.of(context).colorScheme.error;
        break;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// タイトルを構築
  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildAmountText(context),
      ],
    );
  }

  /// サブタイトルを構築
  Widget _buildSubtitle(BuildContext context) {
    final subtitleParts = <String>[];
    
    // 取引日時
    subtitleParts.add(Formatters.formatDateTime(transaction.createdAt));
    
    // 関連する買い物リスト
    if (transaction.shoppingListTitle != null) {
      subtitleParts.add('買い物: ${transaction.shoppingListTitle}');
    }
    
    // 承認者/実行者
    if (transaction.approvedByName != null) {
      subtitleParts.add('承認: ${transaction.approvedByName}');
    }
    
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

  /// トレイリングを構築
  Widget _buildTrailing(BuildContext context) {
    if (onShowDetails != null) {
      return IconButton(
        onPressed: onShowDetails,
        icon: const Icon(Icons.more_vert),
        iconSize: 18,
      );
    }
    return null;
  }

  /// 金額テキストを構築
  Widget _buildAmountText(BuildContext context) {
    final isPositive = transaction.amount > 0;
    final color = isPositive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    
    return Text(
      '${isPositive ? '+' : ''}${Formatters.formatCurrency(transaction.amount)}',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

/// お小遣い取引カード
class AllowanceTransactionCard extends StatelessWidget {
  /// お小遣い取引情報
  final AllowanceTransaction transaction;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// 詳細を表示するコールバック
  final VoidCallback? onShowDetails;

  const AllowanceTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(context),
              if (transaction.shoppingListTitle != null ||
                  transaction.approvedByName != null) ...[
                const SizedBox(height: 8),
                _buildDetails(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(context),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.description,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.formatDateTime(transaction.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        _buildAmountChip(context),
      ],
    );
  }

  /// コンテンツ部分を構築
  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '残高変動: ${Formatters.formatCurrency(transaction.amount)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細情報を構築
  Widget _buildDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transaction.shoppingListTitle != null)
          _buildDetailRow(
            context,
            icon: Icons.shopping_cart,
            label: '買い物リスト',
            value: transaction.shoppingListTitle!,
          ),
        if (transaction.approvedByName != null) ...[
          if (transaction.shoppingListTitle != null)
            const SizedBox(height: 4),
          _buildDetailRow(
            context,
            icon: Icons.person,
            label: '承認者',
            value: transaction.approvedByName!,
          ),
        ],
      ],
    );
  }

  /// 詳細行を構築
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// タイプアイコンを構築
  Widget _buildTypeIcon(BuildContext context) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;
    
    switch (transaction.type) {
      case TransactionType.earned:
        iconData = Icons.add_circle;
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case TransactionType.spent:
        iconData = Icons.remove_circle;
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        iconColor = Theme.of(context).colorScheme.error;
        break;
      case TransactionType.bonus:
        iconData = Icons.star;
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      case TransactionType.penalty:
        iconData = Icons.warning;
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        iconColor = Theme.of(context).colorScheme.error;
        break;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// 金額チップを構築
  Widget _buildAmountChip(BuildContext context) {
    final isPositive = transaction.amount > 0;
    final backgroundColor = isPositive
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    final textColor = isPositive
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${Formatters.formatCurrency(transaction.amount)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}