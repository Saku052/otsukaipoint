import 'package:flutter/material.dart';

/// アプリケーションのカラーパレット
class AppColors {
  // Primary Colors (おつかいテーマ)
  static const Color primary = Color(0xFF4CAF50);      // 緑 (完了・成功)
  static const Color primaryContainer = Color(0xFFE8F5E8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1B5E20);
  
  // Secondary Colors (お小遣いテーマ)
  static const Color secondary = Color(0xFFFF9800);     // オレンジ (お小遣い)
  static const Color secondaryContainer = Color(0xFFFFF3E0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFFE65100);
  
  // Tertiary Colors (親子連携テーマ)
  static const Color tertiary = Color(0xFF2196F3);      // ブルー (連携)
  static const Color tertiaryContainer = Color(0xFFE3F2FD);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF0D47A1);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFF4F4F4);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  
  // Error Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFFB71C1C);
  
  // Background
  static const Color background = Color(0xFFFFFBFE);
  static const Color onBackground = Color(0xFF1C1B1F);
  
  // Custom Colors
  static const Color completed = Color(0xFF4CAF50);     // 完了状態
  static const Color pending = Color(0xFFFF9800);       // 保留状態
  static const Color rejected = Color(0xFFD32F2F);      // 拒否状態
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tertiaryGradient = LinearGradient(
    colors: [tertiary, Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow Colors
  static const Color shadow = Color(0x1F000000);
  static const Color elevation = Color(0x0F000000);
  
  AppColors._();
}