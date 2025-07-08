import 'package:flutter/material.dart';

/// アプリ共通カードコンポーネント
class AppCard extends StatelessWidget {
  /// 子ウィジェット
  final Widget child;
  
  /// パディング
  final EdgeInsets? padding;
  
  /// マージン
  final EdgeInsets? margin;
  
  /// 高さ
  final double? height;
  
  /// 幅
  final double? width;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// 長押し時のコールバック
  final VoidCallback? onLongPress;
  
  /// カードタイプ
  final AppCardType type;
  
  /// 影の高さ
  final double? elevation;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// ボーダー色
  final Color? borderColor;
  
  /// ボーダー幅
  final double borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.onTap,
    this.onLongPress,
    this.type = AppCardType.elevated,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// エレベートカード（影あり）
  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.onTap,
    this.onLongPress,
    this.elevation,
    this.backgroundColor,
  }) : type = AppCardType.elevated,
       borderColor = null,
       borderWidth = 0;

  /// フィルドカード（塗りつぶし）
  const AppCard.filled({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
  }) : type = AppCardType.filled,
       elevation = null,
       borderColor = null,
       borderWidth = 0;

  /// アウトラインカード（ボーダーのみ）
  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  }) : type = AppCardType.outlined,
       elevation = null;

  @override
  Widget build(BuildContext context) {
    final cardChild = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    Widget card;
    
    switch (type) {
      case AppCardType.elevated:
        card = Card(
          elevation: elevation ?? 2,
          color: backgroundColor,
          margin: EdgeInsets.zero,
          child: cardChild,
        );
        break;
        
      case AppCardType.filled:
        card = Card.filled(
          color: backgroundColor,
          margin: EdgeInsets.zero,
          child: cardChild,
        );
        break;
        
      case AppCardType.outlined:
        card = Card(
          color: backgroundColor,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor ?? Theme.of(context).colorScheme.outline,
              width: borderWidth,
            ),
          ),
          child: cardChild,
        );
        break;
    }

    // タップ機能を追加
    if (onTap != null || onLongPress != null) {
      card = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    // サイズ制約を適用
    if (height != null || width != null) {
      card = SizedBox(
        height: height,
        width: width,
        child: card,
      );
    }

    // マージンを適用
    if (margin != null) {
      card = Padding(
        padding: margin!,
        child: card,
      );
    }

    return card;
  }
}

/// 情報カード（アイコン + タイトル + 説明）
class AppInfoCard extends StatelessWidget {
  /// アイコン
  final IconData icon;
  
  /// タイトル
  final String title;
  
  /// 説明
  final String? description;
  
  /// アイコンの色
  final Color? iconColor;
  
  /// アイコンの背景色
  final Color? iconBackgroundColor;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// カードタイプ
  final AppCardType type;

  const AppInfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
    this.type = AppCardType.elevated,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: type,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? 
                     Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// 統計カード（数値 + ラベル）
class AppStatCard extends StatelessWidget {
  /// 値
  final String value;
  
  /// ラベル
  final String label;
  
  /// 変化値（前回との差分）
  final String? change;
  
  /// 変化が正の値かどうか
  final bool? isPositiveChange;
  
  /// アイコン
  final IconData? icon;
  
  /// アイコンの色
  final Color? iconColor;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.change,
    this.isPositiveChange,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          if (change != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositiveChange == true 
                      ? Icons.trending_up 
                      : Icons.trending_down,
                  size: 16,
                  color: isPositiveChange == true 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  change!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPositiveChange == true 
                        ? Colors.green 
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// カードタイプ
enum AppCardType {
  elevated,
  filled,
  outlined,
}