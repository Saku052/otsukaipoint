import 'package:flutter/material.dart';

/// 共通のローディングウィジェット
class LoadingWidget extends StatelessWidget {
  /// サイズ
  final double? size;
  
  /// 色
  final Color? color;
  
  /// メッセージ
  final String? message;

  const LoadingWidget({
    super.key,
    this.size,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final widget = SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget,
          const SizedBox(height: 8),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return widget;
  }
}