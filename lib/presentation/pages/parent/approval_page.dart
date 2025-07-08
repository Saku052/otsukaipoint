import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/approval/approval_provider.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_card.dart';

/// 承認ページ
class ApprovalPage extends ConsumerStatefulWidget {
  const ApprovalPage({super.key});

  @override
  ConsumerState<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends ConsumerState<ApprovalPage> {
  final Set<String> _selectedItems = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    // ページ読み込み時に承認待ち商品を取得
    Future.microtask(() {
      ref.read(approvalProvider.notifier).loadPendingApprovalItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final approvalState = ref.watch(approvalProvider);
    final statsAsync = ref.watch(approvalStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('承認管理'),
        elevation: 0,
        actions: [
          if (approvalState.pendingItems.isNotEmpty && !_isMultiSelectMode)
            IconButton(
              onPressed: _enableMultiSelectMode,
              icon: const Icon(Icons.checklist),
              tooltip: '一括選択',
            ),
          if (_isMultiSelectMode)
            IconButton(
              onPressed: _disableMultiSelectMode,
              icon: const Icon(Icons.close),
              tooltip: '選択モード終了',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(approvalProvider.notifier).loadPendingApprovalItems();
          ref.invalidate(approvalStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(context, statsAsync),
              const SizedBox(height: 24),
              _buildPendingItemsSection(context, approvalState),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isMultiSelectMode && _selectedItems.isNotEmpty
          ? _buildMultiSelectActions(context)
          : null,
    );
  }

  /// 統計セクション
  Widget _buildStatsSection(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '承認状況',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) => Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: '承認待ち',
                  value: '${stats['totalPending'] ?? 0}件',
                  icon: Icons.pending_actions,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: '本日の報告',
                  value: '${stats['todayPending'] ?? 0}件',
                  icon: Icons.today,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: '承認予定額',
                  value: '¥${stats['totalAllowance'] ?? 0}',
                  icon: Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (_, __) => const Center(child: Text('統計の読み込みに失敗しました')),
        ),
      ],
    );
  }

  /// 統計カード
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 承認待ち商品セクション
  Widget _buildPendingItemsSection(BuildContext context, ApprovalState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '承認待ち商品',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (state.pendingItems.isNotEmpty && _isMultiSelectMode)
              TextButton(
                onPressed: _toggleSelectAll,
                child: Text(
                  _selectedItems.length == state.pendingItems.length ? '全選択解除' : '全選択',
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (state.isLoading && state.pendingItems.isEmpty)
          const Center(child: AppLoadingIndicator())
        else if (state.error != null)
          _buildErrorWidget(context, state.error!)
        else if (state.pendingItems.isEmpty)
          _buildEmptyState(context)
        else
          ...state.pendingItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPendingItemCard(context, item),
          )),
      ],
    );
  }

  /// エラーウィジェット
  Widget _buildErrorWidget(BuildContext context, String error) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: '再試行',
            onPressed: () {
              ref.read(approvalProvider.notifier).loadPendingApprovalItems();
            },
          ),
        ],
      ),
    );
  }

  /// 空状態ウィジェット
  Widget _buildEmptyState(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '承認待ちの商品はありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'すべての商品が承認済みです',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 承認待ち商品カード
  Widget _buildPendingItemCard(BuildContext context, ShoppingItem item) {
    final isSelected = _selectedItems.contains(item.id);
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Row(
            children: [
              if (_isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (selected) => _toggleItemSelection(item.id),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '完了報告済み',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 詳細情報
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'お小遣い: ¥${item.allowanceAmount.toInt()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (item.completedAt != null)
                Text(
                  '完了日時: ${item.completedAt!.month}/${item.completedAt!.day} ${item.completedAt!.hour}:${item.completedAt!.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          
          if (!_isMultiSelectMode) ...[
            const SizedBox(height: 16),
            
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: '拒否',
                    type: AppButtonType.outline,
                    size: AppButtonSize.small,
                    onPressed: () => _rejectItem(item),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: '承認してお小遣い付与',
                    size: AppButtonSize.small,
                    icon: Icons.check,
                    onPressed: () => _approveItem(item),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 一括選択アクション
  Widget _buildMultiSelectActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedItems.length}件選択中',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          AppButton(
            text: '一括承認',
            size: AppButtonSize.small,
            onPressed: _approveSelectedItems,
          ),
        ],
      ),
    );
  }

  /// 一括選択モードを有効化
  void _enableMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedItems.clear();
    });
  }

  /// 一括選択モードを無効化
  void _disableMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedItems.clear();
    });
  }

  /// アイテム選択の切り替え
  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  /// 全選択の切り替え
  void _toggleSelectAll() {
    final approvalState = ref.read(approvalProvider);
    setState(() {
      if (_selectedItems.length == approvalState.pendingItems.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(approvalState.pendingItems.map((item) => item.id));
      }
    });
  }

  /// 商品を承認
  Future<void> _approveItem(ShoppingItem item) async {
    final success = await ref.read(approvalProvider.notifier).approveItem(item.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${item.name}」を承認しました'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  /// 商品を拒否
  Future<void> _rejectItem(ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('承認を拒否'),
        content: Text('「${item.name}」の承認を拒否しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('拒否'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(approvalProvider.notifier).rejectItem(item.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${item.name}」を拒否しました'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 選択された商品を一括承認
  Future<void> _approveSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('一括承認'),
        content: Text('選択した${_selectedItems.length}件の商品を承認しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          AppButton(
            text: '承認',
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(approvalProvider.notifier)
          .approveMultipleItems(_selectedItems.toList());
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedItems.length}件の商品を承認しました'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _disableMultiSelectMode();
      }
    }
  }
}