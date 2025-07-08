import 'package:flutter/material.dart';

/// アプリ共通ボタンコンポーネント
class AppButton extends StatelessWidget {
  /// ボタンテキスト
  final String text;
  
  /// タップ時のコールバック
  final VoidCallback? onPressed;
  
  /// ボタンタイプ
  final AppButtonType type;
  
  /// サイズ
  final AppButtonSize size;
  
  /// 幅いっぱいに広げるか
  final bool isFullWidth;
  
  /// ローディング状態
  final bool isLoading;
  
  /// アイコン
  final IconData? icon;
  
  /// アイコンの位置
  final AppButtonIconPosition iconPosition;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
  });

  /// プライマリーボタン
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
  }) : type = AppButtonType.primary;

  /// セカンダリーボタン
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
  }) : type = AppButtonType.secondary;

  /// アウトラインボタン
  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
  }) : type = AppButtonType.outline;

  /// テキストボタン
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
  }) : type = AppButtonType.text;

  @override
  Widget build(BuildContext context) {
    final buttonChild = _buildButtonChild(context);
    final buttonStyle = _getButtonStyle(context);

    Widget button;
    switch (type) {
      case AppButtonType.primary:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case AppButtonType.secondary:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case AppButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  /// ボタンの子要素を構築
  Widget _buildButtonChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getTextColor(context),
          ),
        ),
      );
    }

    if (icon == null) {
      return Text(text);
    }

    final iconWidget = Icon(icon, size: _getIconSize());
    final textWidget = Text(text);
    final spacing = SizedBox(width: _getIconSpacing());

    if (iconPosition == AppButtonIconPosition.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [iconWidget, spacing, textWidget],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [textWidget, spacing, iconWidget],
      );
    }
  }

  /// ボタンスタイルを取得
  ButtonStyle _getButtonStyle(BuildContext context) {
    final baseStyle = _getBaseButtonStyle(context);
    final sizeStyle = _getSizeStyle();
    
    return baseStyle.copyWith(
      padding: sizeStyle.padding,
      minimumSize: sizeStyle.minimumSize,
      textStyle: sizeStyle.textStyle,
    );
  }

  /// 基本ボタンスタイルを取得
  ButtonStyle _getBaseButtonStyle(BuildContext context) {
    switch (type) {
      case AppButtonType.primary:
        return FilledButton.styleFrom();
      case AppButtonType.secondary:
        return FilledButton.styleFrom();
      case AppButtonType.outline:
        return OutlinedButton.styleFrom();
      case AppButtonType.text:
        return TextButton.styleFrom();
    }
  }

  /// サイズスタイルを取得
  _ButtonSizeStyle _getSizeStyle() {
    switch (size) {
      case AppButtonSize.small:
        return _ButtonSizeStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 32)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12),
          ),
        );
      case AppButtonSize.medium:
        return _ButtonSizeStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 40)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 14),
          ),
        );
      case AppButtonSize.large:
        return _ButtonSizeStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16),
          ),
        );
    }
  }

  /// テキストカラーを取得
  Color _getTextColor(BuildContext context) {
    switch (type) {
      case AppButtonType.primary:
        return Theme.of(context).colorScheme.onPrimary;
      case AppButtonType.secondary:
        return Theme.of(context).colorScheme.onSecondaryContainer;
      case AppButtonType.outline:
        return Theme.of(context).colorScheme.primary;
      case AppButtonType.text:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// アイコンサイズを取得
  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  /// アイコンとテキストの間隔を取得
  double _getIconSpacing() {
    switch (size) {
      case AppButtonSize.small:
        return 6;
      case AppButtonSize.medium:
        return 8;
      case AppButtonSize.large:
        return 10;
    }
  }
}

/// ボタンタイプ
enum AppButtonType {
  primary,
  secondary,
  outline,
  text,
}

/// ボタンサイズ
enum AppButtonSize {
  small,
  medium,
  large,
}

/// アイコンの位置
enum AppButtonIconPosition {
  left,
  right,
}

/// ボタンサイズスタイル
class _ButtonSizeStyle {
  final WidgetStateProperty<EdgeInsetsGeometry>? padding;
  final WidgetStateProperty<Size>? minimumSize;
  final WidgetStateProperty<TextStyle?>? textStyle;

  const _ButtonSizeStyle({
    this.padding,
    this.minimumSize,
    this.textStyle,
  });
}