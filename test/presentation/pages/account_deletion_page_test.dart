import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otsukaipoint/presentation/pages/parent/settings/account_deletion_page.dart';
import 'package:otsukaipoint/domain/entities/user.dart';
import 'package:otsukaipoint/application/auth/auth_provider.dart';

void main() {
  group('AccountDeletionPage', () {
    testWidgets('should display warning card', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('重要な注意事項'), findsOneWidget);
      expect(find.text('すべてのお小遣いデータが削除されます'), findsOneWidget);
      expect(find.text('30日間の復旧期間後、完全に削除されます'), findsOneWidget);
    });

    testWidgets('should display deletion reason chips', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('アプリを使わなくなった'), findsOneWidget);
      expect(find.text('他のアプリに移行する'), findsOneWidget);
      expect(find.text('機能に満足できない'), findsOneWidget);
      expect(find.text('プライバシーの懸念'), findsOneWidget);
    });

    testWidgets('should require password for deletion', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('パスワード確認'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('現在のパスワードを入力'), findsOneWidget);
    });

    testWidgets('should require final confirmation checkbox', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('最終確認'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('上記の内容を理解し、アカウントの削除に同意します'), findsOneWidget);
    });

    testWidgets('delete button should be disabled initially', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act & Assert
      final deleteButton = find.text('アカウントを削除する');
      expect(deleteButton, findsOneWidget);
      
      final buttonWidget = tester.widget<ElevatedButton>(
        find.ancestor(
          of: deleteButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNull); // Button should be disabled
    });

    testWidgets('should enable delete button when all conditions are met', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act - Fill password
      await tester.enterText(find.byType(TextFormField), 'test-password');
      await tester.pump();

      // Scroll to make checkbox visible
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        500.0,
      );

      // Act - Check confirmation
      await tester.tap(find.byType(CheckboxListTile), warnIfMissed: false);
      await tester.pump();

      // Scroll to delete button
      await tester.scrollUntilVisible(
        find.text('アカウントを削除する'),
        500.0,
      );

      // Assert
      final deleteButton = find.text('アカウントを削除する');
      final buttonWidget = tester.widget<ElevatedButton>(
        find.ancestor(
          of: deleteButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNotNull); // Button should be enabled
    });

    testWidgets('should display user information correctly', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: MaterialApp(
            home: const AccountDeletionPage(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('削除される情報'), findsOneWidget);
      expect(find.text('Test User (test@example.com)'), findsOneWidget);
      expect(find.text('アカウント情報'), findsOneWidget);
      expect(find.text('家族関係'), findsOneWidget);
      expect(find.text('買い物データ'), findsOneWidget);
      expect(find.text('お小遣いデータ'), findsOneWidget);
    });
  });
}