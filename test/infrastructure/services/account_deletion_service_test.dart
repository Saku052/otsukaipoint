import 'package:flutter_test/flutter_test.dart';
import 'package:otsukaipoint/infrastructure/services/account_deletion_service.dart';

void main() {
  group('AccountDeletionService', () {
    group('AccountDeletionResult', () {
      test('should create result with correct properties', () {
        // Arrange
        final deletedAt = DateTime.now();
        final scheduledDeleteAt = DateTime.now().add(const Duration(days: 30));
        final familyImpact = FamilyImpact(hasImpact: false, affectedMembers: []);

        // Act
        final result = AccountDeletionResult(
          success: true,
          userId: 'test-user-id',
          deletedAt: deletedAt,
          scheduledHardDeleteAt: scheduledDeleteAt,
          familyImpact: familyImpact,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.userId, equals('test-user-id'));
        expect(result.deletedAt, equals(deletedAt));
        expect(result.scheduledHardDeleteAt, equals(scheduledDeleteAt));
        expect(result.familyImpact, equals(familyImpact));
      });
    });

    group('AccountRestorationResult', () {
      test('should create restoration result with correct properties', () {
        // Arrange
        final restoredAt = DateTime.now();

        // Act
        final result = AccountRestorationResult(
          success: true,
          userId: 'test-user-id',
          restoredAt: restoredAt,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.userId, equals('test-user-id'));
        expect(result.restoredAt, equals(restoredAt));
      });
    });

    group('FamilyImpact', () {
      test('should create family impact with no affected members', () {
        // Act
        final impact = FamilyImpact(
          hasImpact: false,
          affectedMembers: [],
        );

        // Assert
        expect(impact.hasImpact, isFalse);
        expect(impact.affectedMembers, isEmpty);
        expect(impact.warningMessage, isNull);
      });

      test('should create family impact with affected members', () {
        // Arrange
        final members = [
          AffectedMember(id: '1', name: 'Child 1', email: 'child1@test.com'),
          AffectedMember(id: '2', name: 'Child 2', email: 'child2@test.com'),
        ];

        // Act
        final impact = FamilyImpact(
          hasImpact: true,
          affectedMembers: members,
          warningMessage: '2人の子どもアカウントが影響を受けます',
        );

        // Assert
        expect(impact.hasImpact, isTrue);
        expect(impact.affectedMembers, hasLength(2));
        expect(impact.warningMessage, equals('2人の子どもアカウントが影響を受けます'));
      });
    });

    group('AffectedMember', () {
      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'name': 'Test Name',
          'email': 'test@example.com',
        };

        // Act
        final member = AffectedMember.fromJson(json);

        // Assert
        expect(member.id, equals('test-id'));
        expect(member.name, equals('Test Name'));
        expect(member.email, equals('test@example.com'));
      });

      test('should handle missing name and email', () {
        // Arrange
        final json = {
          'id': 'test-id',
        };

        // Act
        final member = AffectedMember.fromJson(json);

        // Assert
        expect(member.id, equals('test-id'));
        expect(member.name, equals(''));
        expect(member.email, equals(''));
      });
    });

    group('PendingDeletion', () {
      test('should create from JSON correctly', () {
        // Arrange
        final scheduledDeleteAt = DateTime.now().add(const Duration(days: 30));
        final deletedAt = DateTime.now();
        final json = {
          'id': 'test-user-id',
          'email': 'test@example.com',
          'scheduled_hard_delete_at': scheduledDeleteAt.toIso8601String(),
          'deleted_at': deletedAt.toIso8601String(),
          'deletion_reason': 'テスト理由',
        };

        // Act
        final pending = PendingDeletion.fromJson(json);

        // Assert
        expect(pending.userId, equals('test-user-id'));
        expect(pending.email, equals('test@example.com'));
        expect(pending.scheduledDeleteAt.year, equals(scheduledDeleteAt.year));
        expect(pending.deletedAt.year, equals(deletedAt.year));
        expect(pending.reason, equals('テスト理由'));
      });
    });

    group('DeletionReasonStats', () {
      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'reason': 'アプリを使わなくなった',
          'count': 10,
          'percentage': 25.5,
        };

        // Act
        final stats = DeletionReasonStats.fromJson(json);

        // Assert
        expect(stats.reason, equals('アプリを使わなくなった'));
        expect(stats.count, equals(10));
        expect(stats.percentage, equals(25.5));
      });

      test('should handle missing values with defaults', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final stats = DeletionReasonStats.fromJson(json);

        // Assert
        expect(stats.reason, equals('その他'));
        expect(stats.count, equals(0));
        expect(stats.percentage, equals(0.0));
      });
    });
  });
}

