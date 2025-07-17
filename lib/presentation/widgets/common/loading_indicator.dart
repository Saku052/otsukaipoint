import 'package:flutter/material.dart';

/// アプリ共通ローディングインジケーター
class AppLoadingIndicator extends StatelessWidget {
  /// サイズ
  final AppLoadingSize size;
  
  /// 色
  final Color? color;
  
  /// ストローク幅
  final double? strokeWidth;
  
  /// メッセージ
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingSize.medium,
    this.color,
    this.strokeWidth,
    this.message,
  });

  /// 小さいローディングインジケーター
  const AppLoadingIndicator.small({
    super.key,
    this.color,
    this.strokeWidth,
    this.message,
  }) : size = AppLoadingSize.small;

  /// 大きいローディングインジケーター
  const AppLoadingIndicator.large({
    super.key,
    this.color,
    this.strokeWidth,
    this.message,
  }) : size = AppLoadingSize.large;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = _getSize();
    final indicatorStrokeWidth = strokeWidth ?? _getStrokeWidth();
    
    Widget indicator = SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: indicatorStrokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }

  /// サイズを取得
  double _getSize() {
    switch (size) {
      case AppLoadingSize.small:
        return 20;
      case AppLoadingSize.medium:
        return 32;
      case AppLoadingSize.large:
        return 48;
    }
  }

  /// ストローク幅を取得
  double _getStrokeWidth() {
    switch (size) {
      case AppLoadingSize.small:
        return 2;
      case AppLoadingSize.medium:
        return 3;
      case AppLoadingSize.large:
        return 4;
    }
  }
}

/// フルスクリーンローディングオーバーレイ
class AppLoadingOverlay extends StatelessWidget {
  /// 表示するかどうか
  final bool isLoading;
  
  /// 子ウィジェット
  final Widget child;
  
  /// ローディングメッセージ
  final String? message;
  
  /// 背景色
  final Color? backgroundColor;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? 
                   Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppLoadingIndicator.large(
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// リニアプログレスインジケーター
class AppLinearProgress extends StatelessWidget {
  /// 進捗値（0.0 - 1.0）
  final double? value;
  
  /// 色
  final Color? color;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// 高さ
  final double height;
  
  /// ラベル
  final String? label;
  
  /// パーセンテージ表示
  final bool showPercentage;

  const AppLinearProgress({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.label,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).colorScheme.primary;
    final bgColor = backgroundColor ?? 
                   Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget progress = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          color: progressColor,
          backgroundColor: bgColor,
        ),
      ),
    );

    if (label != null || showPercentage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (showPercentage && value != null)
                  Text(
                    '${(value! * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          progress,
        ],
      );
    }

    return progress;
  }
}

/// ローディング状態を管理するカード
class AppLoadingCard extends StatelessWidget {
  /// ローディング状態
  final bool isLoading;
  
  /// ローディング時に表示する子ウィジェット
  final Widget? loadingChild;
  
  /// 通常時に表示する子ウィジェット
  final Widget child;
  
  /// ローディングメッセージ
  final String? loadingMessage;

  const AppLoadingCard({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingChild,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: loadingChild ??
              AppLoadingIndicator(
                message: loadingMessage,
              ),
        ),
      );
    }

    return child;
  }
}

/// スケルトンローダー
class AppSkeletonLoader extends StatefulWidget {
  /// 幅
  final double? width;
  
  /// 高さ
  final double height;
  
  /// 角丸の半径
  final double borderRadius;

  const AppSkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  /// 円形スケルトンローダー
  const AppSkeletonLoader.circle({
    super.key,
    required double size,
  }) : width = size,
       height = size,
       borderRadius = size / 2;

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

/// ローディングサイズ
enum AppLoadingSize {
  small,
  medium,
  large,
}