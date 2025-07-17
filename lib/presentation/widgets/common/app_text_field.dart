import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// アプリ共通テキストフィールドコンポーネント
class AppTextField extends StatefulWidget {
  /// ラベルテキスト
  final String? label;
  
  /// ヒントテキスト
  final String? hint;
  
  /// ヘルパーテキスト
  final String? helper;
  
  /// エラーテキスト
  final String? error;
  
  /// 初期値
  final String? initialValue;
  
  /// コントローラー
  final TextEditingController? controller;
  
  /// テキスト変更時のコールバック
  final ValueChanged<String>? onChanged;
  
  /// 送信時のコールバック
  final ValueChanged<String>? onSubmitted;
  
  /// フォーカス変更時のコールバック
  final ValueChanged<bool>? onFocusChanged;
  
  /// バリデーション関数
  final String? Function(String?)? validator;
  
  /// キーボードタイプ
  final TextInputType keyboardType;
  
  /// テキスト入力アクション
  final TextInputAction textInputAction;
  
  /// 入力フォーマッター
  final List<TextInputFormatter>? inputFormatters;
  
  /// 最大行数
  final int? maxLines;
  
  /// 最大文字数
  final int? maxLength;
  
  /// 読み取り専用
  final bool readOnly;
  
  /// 有効/無効
  final bool enabled;
  
  /// パスワードフィールド
  final bool obscureText;
  
  /// オートフォーカス
  final bool autofocus;
  
  /// プレフィックスアイコン
  final IconData? prefixIcon;
  
  /// サフィックスアイコン
  final IconData? suffixIcon;
  
  /// サフィックスアイコンタップ時のコールバック
  final VoidCallback? onSuffixIconTap;
  
  /// フィールドサイズ
  final AppTextFieldSize size;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.size = AppTextFieldSize.medium,
  });

  /// パスワードフィールド
  const AppTextField.password({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.size = AppTextFieldSize.medium,
  }) : keyboardType = TextInputType.visiblePassword,
       maxLines = 1,
       maxLength = null,
       obscureText = true,
       suffixIcon = null,
       onSuffixIconTap = null;

  /// メールフィールド
  const AppTextField.email({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.size = AppTextFieldSize.medium,
  }) : keyboardType = TextInputType.emailAddress,
       maxLines = 1,
       maxLength = null,
       obscureText = false;

  /// 数値フィールド
  const AppTextField.number({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.size = AppTextFieldSize.medium,
  }) : keyboardType = TextInputType.number,
       maxLines = 1,
       maxLength = null,
       obscureText = false;

  /// マルチラインフィールド
  const AppTextField.multiline({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.validator,
    this.inputFormatters,
    this.maxLines = 3,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.size = AppTextFieldSize.medium,
  }) : keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       obscureText = false;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _obscureText = widget.obscureText;
    
    if (widget.initialValue != null && widget.controller == null) {
      _controller.text = widget.initialValue!;
    }
    
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: widget.enabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          obscureText: _obscureText,
          autofocus: widget.autofocus,
          style: _getTextStyle(context),
          decoration: _getInputDecoration(context),
        ),
        if (widget.helper != null && widget.error == null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helper!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        if (widget.error != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  /// テキストスタイルを取得
  TextStyle _getTextStyle(BuildContext context) {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return Theme.of(context).textTheme.bodySmall!;
      case AppTextFieldSize.medium:
        return Theme.of(context).textTheme.bodyMedium!;
      case AppTextFieldSize.large:
        return Theme.of(context).textTheme.bodyLarge!;
    }
  }

  /// 入力装飾を取得
  InputDecoration _getInputDecoration(BuildContext context) {
    return InputDecoration(
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon != null
          ? Icon(
              widget.prefixIcon,
              size: _getIconSize(),
            )
          : null,
      suffixIcon: _getSuffixIcon(context),
      errorText: widget.error,
      contentPadding: _getContentPadding(),
      counterText: widget.maxLength != null ? null : '',
    );
  }

  /// サフィックスアイコンを取得
  Widget? _getSuffixIcon(BuildContext context) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: _getIconSize(),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          size: _getIconSize(),
        ),
        onPressed: widget.onSuffixIconTap,
      );
    }

    return null;
  }

  /// コンテンツパディングを取得
  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppTextFieldSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppTextFieldSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  /// アイコンサイズを取得
  double _getIconSize() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return 18;
      case AppTextFieldSize.medium:
        return 20;
      case AppTextFieldSize.large:
        return 22;
    }
  }
}

/// テキストフィールドサイズ
enum AppTextFieldSize {
  small,
  medium,
  large,
}