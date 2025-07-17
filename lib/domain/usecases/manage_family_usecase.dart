import '../entities/family.dart';
import '../entities/notification.dart';
import '../repositories/family_repository.dart';
import '../repositories/notification_repository.dart';

/// 家族管理ユースケース
class ManageFamilyUseCase {
  final FamilyRepository _familyRepository;
  final NotificationRepository _notificationRepository;

  ManageFamilyUseCase(this._familyRepository, this._notificationRepository);

  /// 現在のユーザーの家族を取得
  Future<Family?> getCurrentFamily() async {
    return await _familyRepository.getCurrentFamily();
  }

  /// 家族を作成
  Future<String> createFamily({
    required String name,
    required String createdBy,
  }) async {
    return await _familyRepository.createFamily(
      name: name,
      createdBy: createdBy,
    );
  }

  /// QRコードを生成して更新
  Future<void> generateAndUpdateQrCode({
    required String familyId,
    required String qrCode,
    required DateTime expiresAt,
  }) async {
    await _familyRepository.updateQrCode(
      familyId: familyId,
      qrCode: qrCode,
      expiresAt: expiresAt,
    );
  }

  /// 招待コードで家族に参加
  Future<void> joinFamilyByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    // 家族に参加
    await _familyRepository.joinFamilyByInviteCode(
      inviteCode: inviteCode,
      userId: userId,
      userName: userName,
    );

    // 家族メンバーに通知を送信
    final family = await _familyRepository.getCurrentFamily();
    if (family != null) {
      final members = await _familyRepository.getFamilyMembers(family.id);
      
      for (final member in members) {
        if (member.userId != userId) {
          final notification = Notification(
            id: '', // リポジトリで生成
            userId: member.userId,
            familyId: family.id,
            type: 'family_invitation',
            title: '新しい家族メンバー',
            message: '$userNameが家族に参加しました',
            data: {
              'new_member_id': userId,
              'new_member_name': userName,
            },
            isRead: false,
            createdAt: DateTime.now(),
          );
          await _notificationRepository.createNotification(notification);
        }
      }
    }
  }

  /// 家族メンバーを取得
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    return await _familyRepository.getFamilyMembers(familyId);
  }

  /// 子アカウントを一時停止
  Future<void> suspendChildAccount({
    required String memberId,
    required String suspendedBy,
  }) async {
    await _familyRepository.suspendChildAccount(memberId);
    
    // 通知を送信（実装は省略）
  }

  /// 子アカウントを復活
  Future<void> reactivateChildAccount({
    required String memberId,
    required String reactivatedBy,
  }) async {
    await _familyRepository.reactivateChildAccount(memberId);
    
    // 通知を送信（実装は省略）
  }
}