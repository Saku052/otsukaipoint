import 'package:flutter_test/flutter_test.dart';
import 'package:otsukaipoint/domain/entities/allowance_balance.dart';
import 'package:otsukaipoint/domain/entities/allowance_transaction.dart';

void main() {
  group('AllowanceBalance Tests', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime.parse('2023-01-01T00:00:00.000Z');
    });

    test('残高計算が正しく動作する', () {
      // Arrange
      final balance = AllowanceBalance(
        id: 'test-id',
        userId: 'user-id',
        balance: 500.0,
        totalEarned: 1000.0,
        totalSpent: 500.0,
        lastUpdated: testDateTime,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      // Assert
      expect(balance.balance, 500.0);
      expect(balance.totalEarned, 1000.0);
      expect(balance.totalSpent, 500.0);
    });

    test('残高追加が正しく動作する', () {
      // Arrange
      final initialBalance = AllowanceBalance(
        id: 'test-id',
        userId: 'user-id',
        balance: 500.0,
        totalEarned: 1000.0,
        totalSpent: 500.0,
        lastUpdated: testDateTime,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      // Act
      final newBalance = initialBalance.addBalance(100.0);

      // Assert
      expect(newBalance.balance, 600.0);
      expect(newBalance.totalEarned, 1100.0);
      expect(newBalance.totalSpent, 500.0);
    });

    test('残高減算が正しく動作する', () {
      // Arrange
      final initialBalance = AllowanceBalance(
        id: 'test-id',
        userId: 'user-id',
        balance: 500.0,
        totalEarned: 1000.0,
        totalSpent: 500.0,
        lastUpdated: testDateTime,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      // Act
      final newBalance = initialBalance.subtractBalance(100.0);

      // Assert
      expect(newBalance.balance, 400.0);
      expect(newBalance.totalEarned, 1000.0);
      expect(newBalance.totalSpent, 600.0);
    });

    test('残高不足時の減算でエラーが発生する', () {
      // Arrange
      final balance = AllowanceBalance(
        id: 'test-id',
        userId: 'user-id',
        balance: 50.0,
        totalEarned: 1000.0,
        totalSpent: 950.0,
        lastUpdated: testDateTime,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      // Act & Assert
      expect(
        () => balance.subtractBalance(100.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromMap で正しくオブジェクトが作成される', () {
      // Arrange
      final map = {
        'id': 'test-id',
        'user_id': 'user-id',
        'balance': 500.0,
        'total_earned': 1000.0,
        'total_spent': 500.0,
        'last_updated': '2023-01-01T00:00:00.000Z',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final balance = AllowanceBalance.fromMap(map);

      // Assert
      expect(balance.id, 'test-id');
      expect(balance.userId, 'user-id');
      expect(balance.balance, 500.0);
      expect(balance.totalEarned, 1000.0);
      expect(balance.totalSpent, 500.0);
    });
  });

  group('AllowanceTransaction Tests', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime.parse('2023-01-01T00:00:00.000Z');
    });

    test('取引タイプが正しく判定される', () {
      // Arrange & Act
      final earnedTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.earned,
        amount: 100.0,
        description: 'テスト獲得',
        balanceBefore: 500.0,
        balanceAfter: 600.0,
        transactionDate: testDateTime,
        createdAt: testDateTime,
      );

      final spentTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.spent,
        amount: 100.0,
        description: 'テスト使用',
        balanceBefore: 600.0,
        balanceAfter: 500.0,
        transactionDate: testDateTime,
        createdAt: testDateTime,
      );

      // Assert
      expect(earnedTransaction.isIncome, isTrue);
      expect(earnedTransaction.isExpense, isFalse);
      expect(spentTransaction.isIncome, isFalse);
      expect(spentTransaction.isExpense, isTrue);
    });

    test('今日の取引判定が正しく動作する', () {
      // Arrange
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final todayTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.earned,
        amount: 100.0,
        description: 'テスト獲得',
        balanceBefore: 500.0,
        balanceAfter: 600.0,
        transactionDate: today,
        createdAt: today,
      );

      final yesterdayTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.earned,
        amount: 100.0,
        description: 'テスト獲得',
        balanceBefore: 400.0,
        balanceAfter: 500.0,
        transactionDate: yesterday,
        createdAt: yesterday,
      );

      // Assert
      expect(todayTransaction.isToday, isTrue);
      expect(yesterdayTransaction.isToday, isFalse);
    });

    test('TransactionType.fromString が正しく動作する', () {
      // Act & Assert
      expect(TransactionType.fromString('earned'), TransactionType.earned);
      expect(TransactionType.fromString('spent'), TransactionType.spent);
      expect(TransactionType.fromString('adjustment'), TransactionType.adjustment);
      expect(TransactionType.fromString('bonus'), TransactionType.bonus);
      expect(TransactionType.fromString('penalty'), TransactionType.penalty);
      
      expect(
        () => TransactionType.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TransactionType.displayName が正しい日本語を返す', () {
      // Assert
      expect(TransactionType.earned.displayName, '獲得');
      expect(TransactionType.spent.displayName, '使用');
      expect(TransactionType.adjustment.displayName, '調整');
      expect(TransactionType.bonus.displayName, 'ボーナス');
      expect(TransactionType.penalty.displayName, 'ペナルティ');
    });

    test('fromMap で正しくオブジェクトが作成される', () {
      // Arrange
      final map = {
        'id': 'test-id',
        'user_id': 'user-id',
        'type': 'earned',
        'amount': 100.0,
        'description': 'テスト獲得',
        'balance_before': 500.0,
        'balance_after': 600.0,
        'transaction_date': '2023-01-01T00:00:00.000Z',
        'created_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final transaction = AllowanceTransaction.fromMap(map);

      // Assert
      expect(transaction.id, 'test-id');
      expect(transaction.userId, 'user-id');
      expect(transaction.type, TransactionType.earned);
      expect(transaction.amount, 100.0);
      expect(transaction.description, 'テスト獲得');
      expect(transaction.balanceBefore, 500.0);
      expect(transaction.balanceAfter, 600.0);
    });
  });

  group('取引タイプ統合テスト', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime.parse('2023-01-01T00:00:00.000Z');
    });

    test('ボーナスと通常獲得の判定', () {
      // Arrange
      final bonusTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.bonus,
        amount: 50.0,
        description: 'ボーナス',
        balanceBefore: 500.0,
        balanceAfter: 550.0,
        transactionDate: testDateTime,
        createdAt: testDateTime,
      );

      final earnedTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.earned,
        amount: 100.0,
        description: 'タスク完了',
        balanceBefore: 550.0,
        balanceAfter: 650.0,
        transactionDate: testDateTime,
        createdAt: testDateTime,
      );

      // Assert
      expect(bonusTransaction.isIncome, isTrue);
      expect(earnedTransaction.isIncome, isTrue);
      expect(bonusTransaction.type.displayName, 'ボーナス');
      expect(earnedTransaction.type.displayName, '獲得');
    });

    test('ペナルティと通常使用の判定', () {
      // Arrange
      final penaltyTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.penalty,
        amount: 50.0,
        description: 'ペナルティ',
        balanceBefore: 650.0,
        balanceAfter: 600.0,
        transactionDate: testDateTime,
        createdAt: testDateTime,
      );

      final spentTransaction = AllowanceTransaction(
        id: 'test-id',
        userId: 'user-id',
        type: TransactionType.spent,
        amount: 100.0,
        description: '商品購入',
        balanceBefore: 600.0,
        balanceAfter: 500.0,
        transactionDate: testDateTime,
        createdAt: testDateTime,
      );

      // Assert
      expect(penaltyTransaction.isExpense, isTrue);
      expect(spentTransaction.isExpense, isTrue);
      expect(penaltyTransaction.type.displayName, 'ペナルティ');
      expect(spentTransaction.type.displayName, '使用');
    });
  });
}