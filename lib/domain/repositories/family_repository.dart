import '../entities/family.dart';

/// 家族リポジトリインターフェース
abstract class FamilyRepository {
  /// 現在のユーザーの家族を取得
  Future<Family?> getCurrentFamily();
  
  /// 家族を作成
  Future<String> createFamily({
    required String name,
    required String createdBy,
  });
  
  /// 家族情報を更新
  Future<void> updateFamily(Family family);
  
  /// QRコード情報を更新
  Future<void> updateQrCode({
    required String familyId,
    required String qrCode,
    required DateTime expiresAt,
  });
  
  /// 招待コードで家族に参加
  Future<void> joinFamilyByInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
  });
  
  /// 家族メンバーを取得
  Future<List<FamilyMember>> getFamilyMembers(String familyId);
  
  /// 子アカウントを一時停止
  Future<void> suspendChildAccount(String memberId);
  
  /// 子アカウントを復活
  Future<void> reactivateChildAccount(String memberId);
  
  /// 家族を削除（論理削除）
  Future<void> deleteFamily(String familyId);
}