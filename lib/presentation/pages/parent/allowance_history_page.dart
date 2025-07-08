import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../application/auth/auth_provider.dart';
import '../../../application/family/family_provider.dart';
// import '../../../domain/providers/usecase_providers.dart'; // 一時的に無効化
import '../../../domain/entities/allowance_transaction.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/loading_widget.dart';

/// お小遣い取引履歴画面
class AllowanceHistoryPage extends ConsumerStatefulWidget {
  final String? childId;

  const AllowanceHistoryPage({
    super.key,
    this.childId,
  });

  @override
  ConsumerState<AllowanceHistoryPage> createState() => _AllowanceHistoryPageState();
}

class _AllowanceHistoryPageState extends ConsumerState<AllowanceHistoryPage> {
  String? _selectedChildId;
  List<AllowanceTransaction> _transactions = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    if (_selectedChildId != null) {
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);

    return AppScaffold(
      title: 'お小遣い履歴',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChildSelectionSection(familyState),
            const SizedBox(height: 16),
            if (_selectedChildId != null) ...[
              _buildFilterInfoSection(),
              const SizedBox(height: 16),
              _buildStatisticsSection(),
              const SizedBox(height: 16),
              _buildTransactionsList(),
            ],
          ],
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
            Text(
              '履歴を確認する子を選択',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  _transactions.clear();
                });
                if (value != null) {
                  _loadTransactions();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterInfoSection() {
    if (_startDate == null && _endDate == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '期間: ${_formatDate(_startDate)} ～ ${_formatDate(_endDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _loadTransactions();
              },
              child: const Text('クリア'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalEarned = _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
    
    final totalSpent = _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    final netChange = totalEarned - totalSpent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '統計情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '獲得額',
                    '¥${totalEarned.toStringAsFixed(0)}',
                    Colors.green,
                    Icons.add_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    '使用額',
                    '¥${totalSpent.toStringAsFixed(0)}',
                    Colors.red,
                    Icons.remove_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    '差額',
                    '${netChange >= 0 ? '+' : ''}¥${netChange.toStringAsFixed(0)}',
                    netChange >= 0 ? Colors.blue : Colors.orange,
                    netChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '取引履歴がありません',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '取引履歴 (${_transactions.length}件)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            return _buildTransactionCard(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(AllowanceTransaction transaction) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDateTime(transaction.transactionDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            // 残高履歴を表示（データがある場合のみ）
            if (transaction.balanceBefore != 0.0 && transaction.balanceAfter != 0.0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '残高: ¥${transaction.balanceBefore.toStringAsFixed(0)} → ¥${transaction.balanceAfter.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}¥${transaction.amount.abs().toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            if (transaction.type == 'earned')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '獲得',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontSize: 10,
                      ),
                ),
              )
            else if (transaction.type == 'spent')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '使用',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                        fontSize: 10,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTransactions() async {
    if (_selectedChildId == null) return;

    setState(() => _isLoading = true);

    try {
      // 一時的にダミーデータを使用
      final transactions = <AllowanceTransaction>[
        AllowanceTransaction(
          id: '1',
          userId: _selectedChildId!,
          familyId: 'family1',
          amount: 100.0,
          description: 'お手伝い完了',
          type: 'earned',
          transactionDate: DateTime.now(),
          balanceBefore: 0.0,
          balanceAfter: 100.0,
          createdAt: DateTime.now(),
        ),
        AllowanceTransaction(
          id: '2',
          userId: _selectedChildId!,
          familyId: 'family1',
          amount: -50.0,
          description: 'お菓子購入',
          type: 'spent',
          transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
          balanceBefore: 100.0,
          balanceAfter: 50.0,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('履歴の取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('期間フィルター'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('開始日'),
                  subtitle: Text(_startDate?.toString().split(' ')[0] ?? '選択してください'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        _startDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('終了日'),
                  subtitle: Text(_endDate?.toString().split(' ')[0] ?? '選択してください'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        _endDate = date;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
              _loadTransactions();
            },
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}