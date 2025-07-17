import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../application/family/family_provider.dart';
import '../../../infrastructure/services/qr_service.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_widget.dart';
// import '../../widgets/qr/qr_scanner_widget.dart';

/// QRスキャナー画面
class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinFamilyByCode(String code) async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // 招待コードで家族に参加
      await ref.read(familyProvider.notifier).joinFamilyByInviteCode(
        inviteCode: code,
        userId: user.id,
        userName: user.name ?? user.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('家族への参加が完了しました！'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ダッシュボードに戻る
        context.go('/child/dashboard');
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('家族への参加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processQrCode(String qrData) async {
    try {
      // QRコードデータを解析
      final parsedData = QrService.instance.parseFamilyLinkData(qrData);
      if (parsedData == null) {
        throw Exception('無効なQRコードです');
      }

      final inviteCode = parsedData['invite_code'] as String;
      await _joinFamilyByCode(inviteCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRコードの処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showQrScanner() async {
    // QRスキャナーが一時的に無効化されているため、手動入力を促す
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QRスキャナーは現在利用できません。下の招待コード入力をご利用ください。'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '家族に参加',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 24),
            _buildQrScannerSection(),
            const SizedBox(height: 24),
            _buildManualInputSection(),
            const Spacer(),
            if (_isJoining) ...[
              const LoadingWidget(),
              const SizedBox(height: 16),
              const Text(
                '家族への参加処理中...',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.family_restroom,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '家族に参加する方法',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              step: '1',
              title: '親のQRコードをスキャン',
              description: '親が生成したQRコードをカメラで読み取ります',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              step: '2',
              title: 'または招待コードを入力',
              description: 'QRコードが読み取れない場合は6桁の数字を入力',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              step: '3',
              title: '自動的に家族に参加',
              description: '参加後、買い物リストが利用できるようになります',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrScannerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QRコードをスキャン',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'カメラでQRコードを読み取ります',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'カメラを起動',
              onPressed: _isJoining ? null : () async {
                // QRスキャナーを起動
                await _showQrScanner();
              },
              icon: Icons.camera_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '招待コードで参加',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '親から教えてもらった6桁の招待コードを入力してください',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _inviteCodeController,
              enabled: !_isJoining,
              decoration: const InputDecoration(
                labelText: '招待コード',
                hintText: '123456',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '招待コードを入力してください';
                }
                if (value.length != 6) {
                  return '招待コードは6桁です';
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return '招待コードは数字のみです';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              text: '家族に参加',
              onPressed: _isJoining ? null : () {
                final code = _inviteCodeController.text.trim();
                if (code.length == 6) {
                  _joinFamilyByCode(code);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('6桁の招待コードを入力してください'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              isLoading: _isJoining,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}