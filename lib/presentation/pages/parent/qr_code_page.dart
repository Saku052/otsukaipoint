import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../application/family/family_provider.dart';
import '../../../infrastructure/services/qr_service.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_widget.dart';

/// QRコード生成画面
class QrCodePage extends ConsumerStatefulWidget {
  const QrCodePage({super.key});

  @override
  ConsumerState<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends ConsumerState<QrCodePage> {
  String? _qrData;
  String? _inviteCode;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  Future<void> _generateQrCode() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // 家族情報を取得または作成
      final family = await ref.read(familyProvider.notifier).getCurrentFamily();
      String familyId;
      
      if (family == null) {
        // 家族が存在しない場合は新規作成
        familyId = await ref.read(familyProvider.notifier).createFamily(
          name: '${user.name ?? user.email}の家族',
          createdBy: user.id,
        );
      } else {
        familyId = family.id;
      }

      // 招待コードを生成
      final inviteCode = QrService.instance.generateInviteCode();
      
      // QRコードデータを生成
      final qrData = QrService.instance.generateFamilyLinkData(
        familyId: familyId,
        inviteCode: inviteCode,
      );

      // データベースにQRコード情報を保存
      await ref.read(familyProvider.notifier).updateQrCode(
        familyId: familyId,
        qrCode: qrData,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      setState(() {
        _qrData = qrData;
        _inviteCode = inviteCode;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRコードの生成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'QRコード生成',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 24),
            _buildQrCodeSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
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
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '家族連携の手順',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              step: '1',
              title: 'QRコードを生成',
              description: '下のボタンでQRコードを作成します',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              step: '2',
              title: '子供がスキャン',
              description: '子供のアプリでQRコードを読み取ります',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              step: '3',
              title: '連携完了',
              description: '自動的に家族グループに追加されます',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QRコードの有効期限は5分間です',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
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

  Widget _buildQrCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_isGenerating)
              const Column(
                children: [
                  LoadingWidget(),
                  SizedBox(height: 16),
                  Text('QRコードを生成中...'),
                ],
              )
            else if (_qrData != null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: QrService.instance.generateQrWidget(
                      data: _qrData!,
                      size: 220,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_inviteCode != null) ...[
                    Text(
                      '招待コード',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _inviteCode!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QRコードが読み取れない場合は、この番号を手動入力してください',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              )
            else
              const Column(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('QRコードを生成してください'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: _qrData != null ? 'QRコードを再生成' : 'QRコードを生成',
          onPressed: _isGenerating ? null : _generateQrCode,
          isLoading: _isGenerating,
        ),
        if (_qrData != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: QRコードを共有する機能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('共有機能は実装予定です'),
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('QRコードを共有'),
          ),
        ],
      ],
    );
  }
}