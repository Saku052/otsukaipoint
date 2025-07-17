import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/common/app_scaffold.dart';

/// プライバシー設定画面（親用）
class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  // プライバシー設定の状態
  final bool _allowDataCollection = true; // 必須のため変更不可
  bool _allowAnalytics = false;
  bool _allowLocationTracking = false;
  bool _allowChildProfileSharing = false;
  final bool _allowThirdPartyIntegration = false; // 現在利用不可のため変更不可
  bool _showChildActivity = true;
  bool _parentalControlEnabled = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'プライバシー設定',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroductionCard(),
            const SizedBox(height: 24),
            _buildDataCollectionSection(),
            const SizedBox(height: 24),
            _buildChildProtectionSection(),
            const SizedBox(height: 24),
            _buildAnalyticsSection(),
            const SizedBox(height: 24),
            _buildThirdPartySection(),
            const SizedBox(height: 24),
            _buildDataManagementSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'プライバシーについて',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'おつかいポイントでは、お子様の安全とプライバシーを最優先に考えています。以下の設定で、データの使用方法をコントロールできます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '子供の個人情報は厳重に保護されます',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionSection() {
    return _buildSection(
      title: 'データ収集設定',
      icon: Icons.data_usage,
      children: [
        _buildSwitchTile(
          title: '基本データ収集',
          subtitle: 'アプリの動作に必要な基本データ（必須）',
          value: _allowDataCollection,
          onChanged: null, // 必須なので変更不可
          isRequired: true,
        ),
        _buildSwitchTile(
          title: '位置情報の使用',
          subtitle: '買い物場所の記録（オプション）',
          value: _allowLocationTracking,
          onChanged: (value) => setState(() => _allowLocationTracking = value),
        ),
      ],
    );
  }

  Widget _buildChildProtectionSection() {
    return _buildSection(
      title: '子供の保護設定',
      icon: Icons.child_care,
      children: [
        _buildSwitchTile(
          title: 'ペアレンタルコントロール',
          subtitle: '子供のアクティビティを監視・制限',
          value: _parentalControlEnabled,
          onChanged: (value) => setState(() => _parentalControlEnabled = value),
          isImportant: true,
        ),
        _buildSwitchTile(
          title: '子供の活動表示',
          subtitle: '子供の買い物履歴を親に表示',
          value: _showChildActivity,
          onChanged: (value) => setState(() => _showChildActivity = value),
        ),
        _buildSwitchTile(
          title: 'プロフィール共有制限',
          subtitle: '子供のプロフィール情報の外部共有を制限',
          value: !_allowChildProfileSharing,
          onChanged: (value) => setState(() => _allowChildProfileSharing = !value),
          isReversed: true,
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    return _buildSection(
      title: '分析・改善',
      icon: Icons.analytics,
      children: [
        _buildSwitchTile(
          title: '匿名利用統計',
          subtitle: 'アプリ改善のための匿名データ送信',
          value: _allowAnalytics,
          onChanged: (value) => setState(() => _allowAnalytics = value),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '※ 個人を特定できない形で処理され、アプリの改善にのみ使用されます',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThirdPartySection() {
    return _buildSection(
      title: '外部サービス連携',
      icon: Icons.link,
      children: [
        _buildSwitchTile(
          title: '外部サービス連携',
          subtitle: '家計簿アプリなどとの連携（現在利用不可）',
          value: _allowThirdPartyIntegration,
          onChanged: null, // 現在は利用不可
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '※ 将来的に家計簿アプリなどとの連携機能を提供予定です',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return _buildSection(
      title: 'データ管理',
      icon: Icons.storage,
      children: [
        _buildActionTile(
          title: 'データのエクスポート',
          subtitle: '保存されているデータをダウンロード',
          icon: Icons.download,
          onTap: _exportData,
        ),
        _buildActionTile(
          title: 'データの削除',
          subtitle: '子供のデータを完全に削除',
          icon: Icons.delete_forever,
          iconColor: Colors.red,
          onTap: _showDeleteDataDialog,
        ),
        _buildActionTile(
          title: 'プライバシーポリシー',
          subtitle: '詳細なプライバシーポリシーを確認',
          icon: Icons.policy,
          onTap: _showPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isRequired = false,
    bool isImportant = false,
    bool isReversed = false,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '必須',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isImportant && !isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '推奨',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: isImportant ? Colors.blue : null,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データエクスポート'),
        content: const Text('お子様のデータをエクスポートします。この機能は準備中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データ削除'),
        content: const Text(
          '子供のすべてのデータを完全に削除します。この操作は取り消せません。\n\n本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('データ削除機能は準備中です'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プライバシーポリシー'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'おつかいポイント プライバシーポリシー',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. 収集する情報\n'
                '• 基本的なプロフィール情報（名前、年齢）\n'
                '• 買い物履歴とお小遣いの使用記録\n'
                '• アプリの使用状況（匿名化）\n\n'
                '2. 情報の使用目的\n'
                '• サービスの提供と改善\n'
                '• お子様の安全な利用環境の確保\n'
                '• 親御様への活動報告\n\n'
                '3. 情報の保護\n'
                '• 業界標準の暗号化技術を使用\n'
                '• 第三者への情報提供は行いません\n'
                '• お子様の同意なしに情報を使用しません\n\n'
                '4. データの保存期間\n'
                '• アカウント削除から30日後に完全削除\n'
                '• 法的要請がある場合を除く\n',
              ),
            ],
          ),
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