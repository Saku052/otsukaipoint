import '../entities/allowance_balance.dart';
import '../entities/allowance_transaction.dart';
import '../entities/notification.dart';
import '../repositories/allowance_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/family_repository.dart';

/// お小遣い管理ユースケース
class ManageAllowanceUseCase {
  final AllowanceRepository _allowanceRepository;
  final NotificationRepository _notificationRepository;
  final FamilyRepository _familyRepository;

  ManageAllowanceUseCase(
    this._allowanceRepository,
    this._notificationRepository,
    this._familyRepository,
  );

  /// 残高を取得
  Future<AllowanceBalance?> getBalance(String userId) async {
    return await _allowanceRepository.getBalance(userId);
  }

  /// 手動で残高を調整（親による）
  Future<void> adjustBalance({
    required String userId,
    required String familyId,
    required double amount,
    required String description,
    required String adjustedBy,
  }) async {
    final type = amount > 0 ? 'add' : 'subtract';
    
    // 残高を更新
    await _allowanceRepository.updateBalance(
      userId: userId,
      familyId: familyId,
      amount: amount.abs(),
      type: type,
      description: description,
      adjustedBy: adjustedBy,
    );

    // 通知を送信
    final notification = Notification(
      id: '',
      userId: userId,
      familyId: familyId,
      type: 'allowance_received',
      title: amount > 0 ? 'お小遣いが追加されました' : 'お小遣いが調整されました',
      message: '${amount > 0 ? '+' : ''}${amount.toStringAsFixed(0)}円 - $description',
      data: {
        'amount': amount,
        'type': type,
        'adjusted_by': adjustedBy,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notificationRepository.createNotification(notification);
  }

  /// 取引履歴を取得
  Future<List<AllowanceTransaction>> getTransactions({
    String? userId,
    String? familyId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    return await _allowanceRepository.getTransactions(
      userId: userId,
      familyId: familyId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// お小遣い統計を取得
  Future<Map<String, dynamic>> getAllowanceStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _allowanceRepository.getAllowanceStats(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 家族のお小遣い一覧を取得（親用）
  Future<List<AllowanceBalance>> getFamilyAllowances(String familyId) async {
    return await _allowanceRepository.getFamilyAllowances(familyId);
  }

  /// 商品承認時のお小遣い付与
  Future<void> grantAllowanceForItem({
    required String userId,
    required String familyId,
    required String itemId,
    required double amount,
    required String itemName,
    required String approvedBy,
  }) async {
    // 残高を更新
    await _allowanceRepository.updateBalance(
      userId: userId,
      familyId: familyId,
      amount: amount,
      type: 'add',
      description: 'お使い完了: $itemName',
      adjustedBy: approvedBy,
    );

    // 通知を送信
    final notification = Notification(
      id: '',
      userId: userId,
      familyId: familyId,
      type: 'allowance_received',
      title: 'お小遣いを獲得しました！',
      message: '${amount.toStringAsFixed(0)}円を獲得 - $itemName',
      data: {
        'amount': amount,
        'item_id': itemId,
        'item_name': itemName,
        'approved_by': approvedBy,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notificationRepository.createNotification(notification);
  }

  /// 支出の記録
  Future<void> recordExpense({
    required String userId,
    required String familyId,
    required double amount,
    required String description,
  }) async {
    final balance = await _allowanceRepository.getBalance(userId);
    if (balance == null || !balance.canSpend(amount)) {
      throw Exception('残高が不足しています');
    }

    await _allowanceRepository.updateBalance(
      userId: userId,
      familyId: familyId,
      amount: amount,
      type: 'subtract',
      description: description,
    );
  }
}