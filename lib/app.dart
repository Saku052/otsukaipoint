import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';

/// メインアプリケーションウィジェット
class OtsukaiPointApp extends ConsumerWidget {
  const OtsukaiPointApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // テーマ設定
      theme: AppTheme.lightTheme,
      
      // ルーティング設定
      routerConfig: AppRouter.router,
      
      // 多言語対応（将来的な拡張用）
      locale: const Locale('ja', 'JP'),
      
      // アクセシビリティ設定
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // テキストスケールファクターの制限
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}