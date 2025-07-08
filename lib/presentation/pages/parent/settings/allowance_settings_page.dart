import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_provider.dart';
import '../../../../application/family/family_provider.dart';
import '../../../../domain/providers/usecase_providers.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/loading_widget.dart';

/// お小遣い設定画面
class AllowanceSettingsPage extends ConsumerStatefulWidget {
  const AllowanceSettingsPage({super.key});

  @override
  ConsumerState<AllowanceSettingsPage> createState() => _AllowanceSettingsPageState();
}

class _AllowanceSettingsPageState extends ConsumerState<AllowanceSettingsPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedChildId;
  bool _isAdjusting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final familyState = ref.watch(familyProvider);

    if (user == null) {
      return const AppScaffold(
        title: 'お小遣い設定',
        body: Center(child: LoadingWidget()),
      );
    }

    return AppScaffold(
      title: 'お小遣い設定',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentBalancesSection(familyState),
            const SizedBox(height: 24),
            _buildBalanceAdjustmentSection(familyState),
            const SizedBox(height: 24),
            _buildTransactionHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBalancesSection(familyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '現在の残高',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (familyState.isLoading)
          const Center(child: LoadingWidget())
        else if (familyState.currentFamily?.members.isEmpty ?? true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '子アカウントがありません',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QRコードで子を招待してください',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...familyState.currentFamily!.members
              .where((member) => member.role == 'child')
              .map((child) => _buildChildBalanceCard(child)),
      ],
    );
  }

  Widget _buildChildBalanceCard(child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.userName ?? '子ユーザー',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<double>(
                    future: _getChildBalance(child.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('残高を取得中...');
                      }
                      
                      final balance = snapshot.data ?? 0.0;
                      return Text(
                        '¥${balance.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: balance > 0 ? Colors.green[700] : Colors.grey[600],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    context.push('/parent/allowance/history/${child.userId}');
                  },
                  child: const Text('履歴'),
                ),
                TextButton(
                  onPressed: () {
                    context.push('/parent/allowance/adjust/${child.userId}');
                  },
                  child: const Text('調整'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceAdjustmentSection(familyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '残高調整',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '子のお小遣いを手動で調整できます',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedChildId,
                  decoration: const InputDecoration(
                    labelText: '調整する子を選択',
                    border: OutlineInputBorder(),
                  ),
                  items: familyState.currentFamily?.members
                      .where((member) => member.role == 'child')
                      .map((child) => DropdownMenuItem(
                            value: child.userId,
                            child: Text(child.userName ?? '子ユーザー'),
                          ))
                      .toList() ?? [],
                  onChanged: (value) {
                    setState(() {
                      _selectedChildId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: '調整金額',
                    hintText: '例: 100 (追加) または -50 (減額)',
                    border: OutlineInputBorder(),
                    prefixText: '¥',
                  ),
                  keyboardType: TextInputType.numberWithOptions(signed: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '理由・メモ',
                    hintText: '例: お手伝いのボーナス',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: '残高を調整',
                  onPressed: _selectedChildId == null || _isAdjusting 
                      ? null 
                      : _adjustBalance,
                  isLoading: _isAdjusting,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '取引履歴',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('取引履歴を確認'),
            subtitle: const Text('お小遣いの入出金履歴'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/parent/allowance/history');
            },
          ),
        ),
      ],
    );
  }

  Future<double> _getChildBalance(String childId) async {
    try {
      final manageAllowanceUseCase = ref.read(manageAllowanceUseCaseProvider);
      final balance = await manageAllowanceUseCase.getBalance(childId);
      return balance?.balance ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _adjustBalance() async {
    if (_selectedChildId == null) return;

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('調整金額を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正しい金額を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('理由・メモを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAdjusting = true);

    try {
      final user = ref.read(currentUserProvider);
      final family = ref.read(familyProvider).currentFamily;
      
      if (user == null || family == null) {
        throw Exception('ユーザー情報または家族情報が取得できません');
      }

      final manageAllowanceUseCase = ref.read(manageAllowanceUseCaseProvider);
      await manageAllowanceUseCase.adjustBalance(
        userId: _selectedChildId!,
        familyId: family.id,
        amount: amount,
        description: description,
        adjustedBy: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('残高を${amount > 0 ? "+" : ""}${amount.toStringAsFixed(0)}円調整しました'),
            backgroundColor: Colors.green,
          ),
        );

        // フォームをクリア
        _amountController.clear();
        _descriptionController.clear();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('残高調整に失敗しました: $e'),
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