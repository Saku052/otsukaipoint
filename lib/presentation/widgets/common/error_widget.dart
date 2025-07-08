import 'package:flutter/material.dart';

/// アプリ共通エラーウィジェット
class AppErrorWidget extends StatelessWidget {
  /// エラーメッセージ
  final String message;
  
  /// 再試行ボタンのコールバック
  final VoidCallback? onRetry;
  
  /// 再試行ボタンのテキスト
  final String? retryText;
  
  /// アイコン
  final IconData? icon;
  
  /// エラータイプ
  final AppErrorType type;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText,
    this.icon,
    this.type = AppErrorType.general,
  });

  /// ネットワークエラー
  const AppErrorWidget.network({
    super.key,
    this.message = 'インターネット接続を確認してください',
    this.onRetry,
    this.retryText,
  }) : icon = Icons.wifi_off,
       type = AppErrorType.network;

  /// サーバーエラー
  const AppErrorWidget.server({
    super.key,
    this.message = 'サーバーエラーが発生しました',
    this.onRetry,
    this.retryText,
  }) : icon = Icons.error_outline,
       type = AppErrorType.server;

  /// データが見つからない
  const AppErrorWidget.notFound({
    super.key,
    this.message = 'データが見つかりません',
    this.onRetry,
    this.retryText,
  }) : icon = Icons.search_off,
       type = AppErrorType.notFound;

  /// 権限エラー
  const AppErrorWidget.permission({
    super.key,
    this.message = '権限がありません',
    this.onRetry,
    this.retryText,
  }) : icon = Icons.lock,
       type = AppErrorType.permission;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? _getDefaultIcon(),
              size: 64,
              color: _getIconColor(context),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryText ?? '再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// デフォルトアイコンを取得
  IconData _getDefaultIcon() {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.server:
        return Icons.error_outline;
      case AppErrorType.notFound:
        return Icons.search_off;
      case AppErrorType.permission:
        return Icons.lock;
      case AppErrorType.general:
        return Icons.error_outline;
    }
  }

  /// アイコンの色を取得
  Color _getIconColor(BuildContext context) {
    switch (type) {
      case AppErrorType.network:
        return Theme.of(context).colorScheme.outline;
      case AppErrorType.server:
        return Theme.of(context).colorScheme.error;
      case AppErrorType.notFound:
        return Theme.of(context).colorScheme.outline;
      case AppErrorType.permission:
        return Theme.of(context).colorScheme.error;
      case AppErrorType.general:
        return Theme.of(context).colorScheme.error;
    }
  }
}

/// インラインエラーウィジェット（フォーム等で使用）
class AppInlineError extends StatelessWidget {
  /// エラーメッセージ
  final String message;
  
  /// アイコン
  final IconData? icon;

  const AppInlineError({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// エラーバナー（画面上部に表示）
class AppErrorBanner extends StatelessWidget {
  /// エラーメッセージ
  final String message;
  
  /// 閉じるボタンのコールバック
  final VoidCallback? onClose;
  
  /// 再試行ボタンのコールバック
  final VoidCallback? onRetry;
  
  /// エラータイプ
  final AppErrorType type;

  const AppErrorBanner({
    super.key,
    required this.message,
    this.onClose,
    this.onRetry,
    this.type = AppErrorType.general,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        border: Border(
          bottom: BorderSide(
            color: _getBorderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            size: 20,
            color: _getIconColor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getTextColor(context),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: Text(
                '再試行',
                style: TextStyle(
                  color: _getActionColor(context),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                size: 18,
                color: _getIconColor(context),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  /// アイコンを取得
  IconData _getIcon() {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.server:
        return Icons.error_outline;
      case AppErrorType.notFound:
        return Icons.info_outline;
      case AppErrorType.permission:
        return Icons.lock;
      case AppErrorType.general:
        return Icons.warning;
    }
  }

  /// 背景色を取得
  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case AppErrorType.network:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      case AppErrorType.server:
      case AppErrorType.permission:
      case AppErrorType.general:
        return Theme.of(context).colorScheme.errorContainer;
      case AppErrorType.notFound:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  /// ボーダー色を取得
  Color _getBorderColor(BuildContext context) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.notFound:
        return Theme.of(context).colorScheme.outline;
      case AppErrorType.server:
      case AppErrorType.permission:
      case AppErrorType.general:
        return Theme.of(context).colorScheme.error;
    }
  }

  /// アイコン色を取得
  Color _getIconColor(BuildContext context) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.notFound:
        return Theme.of(context).colorScheme.onSurface;
      case AppErrorType.server:
      case AppErrorType.permission:
      case AppErrorType.general:
        return Theme.of(context).colorScheme.error;
    }
  }

  /// テキスト色を取得
  Color _getTextColor(BuildContext context) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.notFound:
        return Theme.of(context).colorScheme.onSurface;
      case AppErrorType.server:
      case AppErrorType.permission:
      case AppErrorType.general:
        return Theme.of(context).colorScheme.onErrorContainer;
    }
  }

  /// アクション色を取得
  Color _getActionColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
}

/// エラータイプ
enum AppErrorType {
  general,
  network,
  server,
  notFound,
  permission,
}