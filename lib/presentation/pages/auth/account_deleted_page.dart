import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../infrastructure/services/account_deletion_service.dart';
import '../../widgets/common/app_scaffold.dart';

/// アカウント削除完了画面
class AccountDeletedPage extends ConsumerWidget {
  final DateTime scheduledDeleteAt;
  final FamilyImpact? familyImpact;

  const AccountDeletedPage({
    super.key,
    required this.scheduledDeleteAt,
    this.familyImpact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'アカウント削除完了',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSuccessIcon(context),
            const SizedBox(height: 32),
            _buildMainMessage(context),
            const SizedBox(height: 24),
            _buildDeletionSchedule(context),
            if (familyImpact?.hasImpact == true) ...[
              const SizedBox(height: 24),
              _buildFamilyImpactCard(context),
            ],
            const SizedBox(height: 32),
            _buildRestoreInformation(context),
            const SizedBox(height: 40),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.schedule,
        size: 60,
        color: Colors.orange.shade600,
      ),
    );
  }

  Widget _buildMainMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'アカウント削除の手続きが\n完了しました',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'アカウントは一時的に非表示になり、30日後に完全に削除されます。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildDeletionSchedule(BuildContext context) {
    final deleteDate = _formatDateTime(scheduledDeleteAt);
    
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '完全削除予定日',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              deleteDate,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'この日付以降、データの復旧はできません',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyImpactCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.family_restroom,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '家族への影響',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (familyImpact?.warningMessage != null)
              Text(
                familyImpact!.warningMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade800,
                ),
              ),
            if (familyImpact?.affectedMembers.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                '影響を受ける子どもアカウント:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              ...familyImpact!.affectedMembers.map((member) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '• ${member.name} (${member.email})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreInformation(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.restore,
                  color: Colors.green.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'アカウントの復旧について',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_formatDateTime(scheduledDeleteAt)}まで、同じメールアドレスとパスワードでログインすることで、アカウントを復旧できます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '復旧後は、削除前のデータがそのまま利用できます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'ログイン画面に戻る',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _showContactSupport(context),
          child: const Text(
            'サポートに問い合わせる',
            style: TextStyle(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サポートへの問い合わせ'),
        content: const Text(
          'アカウント削除やデータ復旧に関してご質問がございましたら、'
          'アプリ内のヘルプセンターまたはサポートメールまでお問い合わせください。\n\n'
          'support@otsukaipoint.jp',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}