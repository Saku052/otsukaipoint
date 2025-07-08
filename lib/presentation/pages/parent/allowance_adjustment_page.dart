import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../application/family/family_provider.dart';
import '../../../domain/providers/usecase_providers.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_widget.dart';

/// お小遣い残高調整画面
class AllowanceAdjustmentPage extends ConsumerStatefulWidget {
  final String? childId;

  const AllowanceAdjustmentPage({
    super.key,
    this.childId,
  });

  @override
  ConsumerState<AllowanceAdjustmentPage> createState() => _AllowanceAdjustmentPageState();
}

class _AllowanceAdjustmentPageState extends ConsumerState<AllowanceAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  
  String? _selectedChildId;
  String _adjustmentType = 'add'; // 'add' or 'subtract'
  bool _isAdjusting = false;
  List<Map<String, dynamic>> _presetAmounts = [];

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _initializePresetAmounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _initializePresetAmounts() {
    _presetAmounts = [
      {'label': '100円', 'amount': 100.0, 'reason': 'お手伝いボーナス'},
      {'label': '200円', 'amount': 200.0, 'reason': 'お手伝いボーナス'},
      {'label': '500円', 'amount': 500.0, 'reason': '週末ボーナス'},
      {'label': '1000円', 'amount': 1000.0, 'reason': '月間ボーナス'},
      {'label': '50円', 'amount': 50.0, 'reason': '小さなお手伝い'},
      {'label': '300円', 'amount': 300.0, 'reason': '宿題完了ボーナス'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final familyState = ref.watch(familyProvider);

    return AppScaffold(
      title: 'お小遣い調整',
      body: user == null
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChildSelectionSection(familyState),
                    const SizedBox(height: 24),
                    if (_selectedChildId != null) ...[
                      _buildCurrentBalanceSection(),
                      const SizedBox(height: 24),
                      _buildAdjustmentTypeSection(),
                      const SizedBox(height: 24),
                      _buildPresetAmountsSection(),
                      const SizedBox(height: 24),
                      _buildCustomAmountSection(),
                      const SizedBox(height: 24),
                      _buildReasonSection(),
                      const SizedBox(height: 24),
                      _buildConfirmationSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChildSelectionSection(familyState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '調整する子を選択',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedChildId,
              decoration: const InputDecoration(
                labelText: '子アカウント',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.child_care),
              ),
              items: familyState.currentFamily?.members
                  .where((member) => member.role == 'child')
                  .map<DropdownMenuItem<String>>((child) => DropdownMenuItem(
                        value: child.userId,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.child_care,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(child.userName ?? '子ユーザー'),
                          ],
                        ),
                      ))
                  .toList() ?? [],
              onChanged: (value) {
                setState(() {
                  _selectedChildId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return '子アカウントを選択してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBalanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '現在の残高',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<double>(
              future: _getCurrentBalance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingWidget());
                }
                
                final balance = snapshot.data ?? 0.0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '¥${balance.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '現在の残高',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '調整の種類',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    type: 'add',
                    label: '追加',
                    icon: Icons.add_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    type: 'subtract',
                    label: '減額',
                    icon: Icons.remove_circle,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _adjustmentType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _adjustmentType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetAmountsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'クイック選択',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetAmounts.map((preset) {
                return InkWell(
                  onTap: () {
                    _amountController.text = preset['amount'].toString();
                    _reasonController.text = preset['reason'];
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      preset['label'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAmountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '金額を入力',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '調整金額',
                hintText: '例: 100',
                border: const OutlineInputBorder(),
                prefixText: '¥ ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _amountController.clear(),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '金額を入力してください';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '正しい金額を入力してください';
                }
                if (amount > 10000) {
                  return '1回の調整は10,000円以下にしてください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '理由・メモ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '調整理由',
                hintText: '例: お手伝いのご褒美、宿題完了ボーナス',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '調整理由を入力してください';
                }
                if (value.trim().length < 3) {
                  return '理由は3文字以上で入力してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '調整内容の確認',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmationRow(
                    '調整種類', 
                    _adjustmentType == 'add' ? '追加' : '減額',
                    _adjustmentType == 'add' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildConfirmationRow(
                    '金額', 
                    _amountController.text.isNotEmpty 
                        ? '¥${_amountController.text}' 
                        : '未入力',
                    null,
                  ),
                  const SizedBox(height: 8),
                  _buildConfirmationRow(
                    '理由', 
                    _reasonController.text.isNotEmpty 
                        ? _reasonController.text 
                        : '未入力',
                    null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: '残高を調整',
              onPressed: _isAdjusting ? null : _performAdjustment,
              isLoading: _isAdjusting,
              isFullWidth: true,
              icon: _adjustmentType == 'add' ? Icons.add : Icons.remove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value, Color? valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Future<double> _getCurrentBalance() async {
    if (_selectedChildId == null) return 0.0;
    
    try {
      final manageAllowanceUseCase = ref.read(manageAllowanceUseCaseProvider);
      final balance = await manageAllowanceUseCase.getBalance(_selectedChildId!);
      return balance?.balance ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _performAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChildId == null) return;

    setState(() => _isAdjusting = true);

    try {
      final user = ref.read(currentUserProvider);
      final family = ref.read(familyProvider).currentFamily;
      
      if (user == null || family == null) {
        throw Exception('ユーザー情報または家族情報が取得できません');
      }

      final amount = double.parse(_amountController.text);
      final adjustedAmount = _adjustmentType == 'add' ? amount : -amount;

      final manageAllowanceUseCase = ref.read(manageAllowanceUseCaseProvider);
      await manageAllowanceUseCase.adjustBalance(
        userId: _selectedChildId!,
        familyId: family.id,
        amount: adjustedAmount,
        description: _reasonController.text.trim(),
        adjustedBy: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¥${amount.toStringAsFixed(0)}を${_adjustmentType == 'add' ? '追加' : '減額'}しました',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // フォームをリセット
        _amountController.clear();
        _reasonController.clear();
        
        // 前の画面に戻る
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('調整に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdjusting = false);
      }
    }
  }
}