import 'package:flutter/material.dart';

/// アプリ共通空状態ウィジェット
class AppEmptyStateWidget extends StatelessWidget {
  /// タイトル
  final String title;
  
  /// 説明
  final String? description;
  
  /// アイコン
  final IconData? icon;
  
  /// イラスト画像パス
  final String? imagePath;
  
  /// アクションボタンのテキスト
  final String? actionText;
  
  /// アクションボタンのコールバック
  final VoidCallback? onAction;
  
  /// 空状態のタイプ
  final AppEmptyStateType type;

  const AppEmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.imagePath,
    this.actionText,
    this.onAction,
    this.type = AppEmptyStateType.general,
  });

  /// 買い物リストが空の状態
  const AppEmptyStateWidget.shoppingList({
    super.key,
    this.title = '買い物リストがありません',
    this.description = '新しい買い物リストを作成してお使いを始めましょう',
    this.actionText = 'リストを作成',
    this.onAction,
  }) : icon = Icons.shopping_cart_outlined,
       imagePath = null,
       type = AppEmptyStateType.shoppingList;

  /// 商品が空の状態
  const AppEmptyStateWidget.shoppingItems({
    super.key,
    this.title = '商品がありません',
    this.description = 'まだ商品が追加されていません',
    this.actionText = '商品を追加',
    this.onAction,
  }) : icon = Icons.add_shopping_cart,
       imagePath = null,
       type = AppEmptyStateType.shoppingItems;

  /// 通知が空の状態
  const AppEmptyStateWidget.notifications({
    super.key,
    this.title = '通知がありません',
    this.description = '新しい通知があるとここに表示されます',
  }) : icon = Icons.notifications_none,
       imagePath = null,
       actionText = null,
       onAction = null,
       type = AppEmptyStateType.notifications;

  /// お小遣い履歴が空の状態
  const AppEmptyStateWidget.allowanceHistory({
    super.key,
    this.title = '履歴がありません',
    this.description = 'お使いを完了すると履歴が表示されます',
  }) : icon = Icons.history,
       imagePath = null,
       actionText = null,
       onAction = null,
       type = AppEmptyStateType.allowanceHistory;

  /// 検索結果が空の状態
  const AppEmptyStateWidget.searchResults({
    super.key,
    this.title = '検索結果がありません',
    this.description = '別のキーワードで検索してみてください',
  }) : icon = Icons.search_off,
       imagePath = null,
       actionText = null,
       onAction = null,
       type = AppEmptyStateType.searchResults;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVisual(context),
            
            const SizedBox(height: 24),
            
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ビジュアル要素を構築
  Widget _buildVisual(BuildContext context) {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.inbox_outlined,
        size: 40,
        color: _getIconColor(context),
      ),
    );
  }

  /// アイコンの背景色を取得
  Color _getIconBackgroundColor(BuildContext context) {
    switch (type) {
      case AppEmptyStateType.shoppingList:
      case AppEmptyStateType.shoppingItems:
        return Theme.of(context).colorScheme.primaryContainer;
      case AppEmptyStateType.notifications:
        return Theme.of(context).colorScheme.secondaryContainer;
      case AppEmptyStateType.allowanceHistory:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case AppEmptyStateType.searchResults:
      case AppEmptyStateType.general:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  /// アイコンの色を取得
  Color _getIconColor(BuildContext context) {
    switch (type) {
      case AppEmptyStateType.shoppingList:
      case AppEmptyStateType.shoppingItems:
        return Theme.of(context).colorScheme.primary;
      case AppEmptyStateType.notifications:
        return Theme.of(context).colorScheme.secondary;
      case AppEmptyStateType.allowanceHistory:
        return Theme.of(context).colorScheme.tertiary;
      case AppEmptyStateType.searchResults:
      case AppEmptyStateType.general:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }
}

/// コンパクトな空状態ウィジェット（リスト内で使用）
class AppCompactEmptyState extends StatelessWidget {
  /// メッセージ
  final String message;
  
  /// アイコン
  final IconData? icon;
  
  /// アクションテキスト
  final String? actionText;
  
  /// アクションコールバック
  final VoidCallback? onAction;

  const AppCompactEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
          ],
          
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

/// リスト用の空状態アイテム
class AppEmptyListItem extends StatelessWidget {
  /// メッセージ
  final String message;
  
  /// アイコン
  final IconData? icon;
  
  /// 高さ
  final double height;

  const AppEmptyListItem({
    super.key,
    required this.message,
    this.icon,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状態のタイプ
enum AppEmptyStateType {
  general,
  shoppingList,
  shoppingItems,
  notifications,
  allowanceHistory,
  searchResults,
}