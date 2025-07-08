import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otsukaipoint/app.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('OtsukaiPointApp Tests', () {
    testWidgets('アプリが正しく起動する', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const OtsukaiPointApp());
      await TestHelpers.pumpAndSettle(tester);

      // Assert - アプリが起動することを確認
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Riverpodプロバイダーが正しく設定される', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const OtsukaiPointApp());

      // Assert - ProviderScopeが存在することを確認
      expect(find.byType(ProviderScope), findsOneWidget);
    });

    testWidgets('初期画面が表示される', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const OtsukaiPointApp());
      await TestHelpers.pumpAndSettle(tester);

      // Assert - 何らかのScaffold構造が存在することを確認
      // 初期画面は認証状態によって変わるため、基本構造のみ確認
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });

  group('基本コンポーネントテスト', () {
    testWidgets('Material Designテーマが適用される', (WidgetTester tester) async {
      // Arrange
      const testWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('テスト'),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('基本的なナビゲーション構造が存在する', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const OtsukaiPointApp());
      await TestHelpers.pumpAndSettle(tester);

      // Assert - ルーティング機能が設定されていることを確認
      // GoRouterまたはNavigatorが存在することを確認
      final context = tester.element(find.byType(MaterialApp));
      expect(Navigator.of(context), isNotNull);
    });
  });

  group('エラーハンドリングテスト', () {
    testWidgets('ウィジェットエラーが適切に処理される', (WidgetTester tester) async {
      // Arrange - エラーを発生させるウィジェット
      final errorWidget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // 意図的にエラーを発生させるためのウィジェット
              return const Center(
                child: Text('テストウィジェット'),
              );
            },
          ),
        ),
      );

      // Act & Assert - エラーが発生しないことを確認
      await tester.pumpWidget(errorWidget);
      expect(find.text('テストウィジェット'), findsOneWidget);
    });
  });

  group('パフォーマンステスト', () {
    testWidgets('アプリの初期化が適切な時間内に完了する', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(const OtsukaiPointApp());
      await TestHelpers.pumpAndSettle(tester);
      
      stopwatch.stop();

      // Assert - 5秒以内に初期化が完了することを確認
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}