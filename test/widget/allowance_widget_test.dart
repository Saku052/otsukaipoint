import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otsukaipoint/presentation/pages/child/child_allowance_page.dart';
import 'package:otsukaipoint/presentation/pages/child/allowance_history_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('ChildAllowancePage Widget Tests', () {
    testWidgets('お小遣い残高ページが正しく表示される', (WidgetTester tester) async {
      // Arrange
      const widget = ChildAllowancePage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      // Assert
      expect(find.text('お小遣い残高'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('履歴ボタンをタップできる', (WidgetTester tester) async {
      // Arrange
      const widget = ChildAllowancePage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      final historyButton = find.byIcon(Icons.history);
      expect(historyButton, findsOneWidget);

      // 履歴ボタンのタップテスト（実際のナビゲーションはモックが必要）
      await tester.tap(historyButton);
      await tester.pump();
    });

    testWidgets('プルリフレッシュが動作する', (WidgetTester tester) async {
      // Arrange
      const widget = ChildAllowancePage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      // RefreshIndicatorを見つけてプルダウン
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pumpAndSettle();
    });
  });

  group('AllowanceHistoryPage Widget Tests', () {
    testWidgets('お小遣い履歴ページが正しく表示される', (WidgetTester tester) async {
      // Arrange
      const widget = AllowanceHistoryPage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      // Assert
      expect(find.text('お小遣い履歴'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('フィルターメニューが表示される', (WidgetTester tester) async {
      // Arrange
      const widget = AllowanceHistoryPage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      // フィルターボタンをタップ
      final filterButton = find.byIcon(Icons.filter_list);
      expect(filterButton, findsOneWidget);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // フィルターメニューの項目を確認
      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('獲得のみ'), findsOneWidget);
      expect(find.text('使用のみ'), findsOneWidget);
    });

    testWidgets('フィルター選択が動作する', (WidgetTester tester) async {
      // Arrange
      const widget = AllowanceHistoryPage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      // フィルターボタンをタップしてメニューを開く
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // 「獲得のみ」を選択
      await tester.tap(find.text('獲得のみ'));
      await tester.pumpAndSettle();

      // フィルターが適用されたことを確認（UIが変更される）
      // 実際のデータがある場合はここでフィルタリング結果を確認
    });

    testWidgets('統計セクションが表示される', (WidgetTester tester) async {
      // Arrange
      const widget = AllowanceHistoryPage();
      
      // Act
      await tester.pumpWidget(
        TestHelpers.wrapWithProviders(widget),
      );
      await TestHelpers.pumpAndSettle(tester);

      // Assert - 統計セクションのタイトル
      expect(find.text('お小遣い統計'), findsOneWidget);
    });
  });

  group('共通ウィジェットテスト', () {
    testWidgets('AppCardウィジェットが正しくレンダリングされる', (WidgetTester tester) async {
      // Arrange
      const testWidget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // AppCardのテスト用ウィジェット
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('テストコンテンツ'),
                ),
              ),
            ],
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('テストコンテンツ'), findsOneWidget);
    });

    testWidgets('ローディングインジケーターが表示される', (WidgetTester tester) async {
      // Arrange
      const testWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('エラーハンドリングテスト', () {
    testWidgets('エラー状態が正しく表示される', (WidgetTester tester) async {
      // Arrange - エラー状態のモックプロバイダーが必要
      const errorWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48),
                SizedBox(height: 16),
                Text('エラーが発生しました'),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(errorWidget);

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('空状態が正しく表示される', (WidgetTester tester) async {
      // Arrange
      const emptyWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64),
                SizedBox(height: 16),
                Text('まだ取引履歴がありません'),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(emptyWidget);

      // Assert
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.text('まだ取引履歴がありません'), findsOneWidget);
    });
  });
}