import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用のヘルパークラス
class TestHelpers {
  /// テスト用ウィジェットのラップ
  static Widget wrapWithProviders(
    Widget child, {
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// 非同期操作の完了を待つ
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// 指定時間待機
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }

  /// テキストフィールドに入力
  static Future<void> enterText(
    WidgetTester tester,
    String text,
    Finder finder,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// ボタンをタップ
  static Future<void> tapButton(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
  }
}

/// テスト用の定数
class TestConstants {
  static const String testUserId = 'test-user-id';
  static const String testFamilyId = 'test-family-id';
  static const String testListId = 'test-list-id';
  static const String testItemId = 'test-item-id';
  static const double testAmount = 100.0;
  static const String testUserName = 'テストユーザー';
  static const String testFamilyName = 'テスト家族';
}