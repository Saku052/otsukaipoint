import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/shopping/shopping_list_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_card.dart';

/// 買い物リスト作成ページ
class CreateShoppingListPage extends ConsumerStatefulWidget {
  const CreateShoppingListPage({super.key});

  @override
  ConsumerState<CreateShoppingListPage> createState() => _CreateShoppingListPageState();
}

class _CreateShoppingListPageState extends ConsumerState<CreateShoppingListPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final List<ShoppingItemForm> _items = [];
  DateTime? _deadline;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物リスト作成'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildItemsSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  /// 基本情報セクション
  Widget _buildBasicInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基本情報',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // タイトル入力
          AppTextField(
            controller: _titleController,
            label: 'リスト名',
            hint: '例: 今日の買い物',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'リスト名を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 説明入力
          AppTextField(
            controller: _descriptionController,
            label: '説明（任意）',
            hint: '買い物の詳細や注意事項など',
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // 期限設定は一時的に無効化（DBカラムが存在しない）
          // _buildDeadlineSelector(),
        ],
      ),
    );
  }

  /// 期限選択ウィジェット
  Widget _buildDeadlineSelector() {
    return InkWell(
      onTap: _selectDeadline,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '期限',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _deadline != null
                        ? '${_deadline!.month}/${_deadline!.day} ${_deadline!.hour}:${_deadline!.minute.toString().padLeft(2, '0')}'
                        : '期限を設定（任意）',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _deadline != null 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (_deadline != null)
              IconButton(
                onPressed: () => setState(() => _deadline = null),
                icon: const Icon(Icons.clear),
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// 商品セクション
  Widget _buildItemsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '商品リスト',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppButton(
                text: '商品を追加',
                type: AppButtonType.outline,
                size: AppButtonSize.small,
                onPressed: _addItem,
                icon: Icons.add,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '商品を追加してください',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_items.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index < _items.length - 1 ? 16 : 0),
                child: _buildItemCard(index),
              );
            }),
        ],
      ),
    );
  }

  /// 商品カード
  Widget _buildItemCard(int index) {
    final item = _items[index];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '商品 ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          AppTextField(
            controller: item.nameController,
            label: '商品名',
            hint: '例: 牛乳',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '商品名を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          AppTextField(
            controller: item.descriptionController,
            label: '説明（任意）',
            hint: '例: 1リットル、低脂肪',
            maxLines: 2,
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: item.priceController,
                  label: '予想価格（任意）',
                  hint: '例: 200',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: item.allowanceController,
                  label: 'お小遣い',
                  hint: '例: 50',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.account_balance_wallet,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return '正しい金額を入力してください';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          AppTextField(
            controller: item.storeController,
            label: '推奨店舗（任意）',
            hint: '例: スーパーA',
            prefixIcon: Icons.store,
          ),
        ],
      ),
    );
  }

  /// ボトムバー
  Widget _buildBottomBar() {
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
          Expanded(
            child: AppButton(
              text: 'キャンセル',
              type: AppButtonType.outline,
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              text: 'リストを作成',
              onPressed: _isCreating ? null : _createShoppingList,
              isLoading: _isCreating,
            ),
          ),
        ],
      ),
    );
  }

  /// 期限選択
  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now().add(const Duration(hours: 1))),
      );

      if (time != null && mounted) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// 商品を追加
  void _addItem() {
    setState(() {
      _items.add(ShoppingItemForm());
    });
  }

  /// 商品を削除
  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  /// 買い物リストを作成
  Future<void> _createShoppingList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final items = _items.map((item) {
        return {
          'name': item.nameController.text.trim(),
          'description': item.descriptionController.text.trim().isEmpty
              ? null
              : item.descriptionController.text.trim(),
          'estimated_price': item.priceController.text.trim().isEmpty
              ? null
              : double.tryParse(item.priceController.text.trim()),
          'allowance_amount': item.allowanceController.text.trim().isEmpty
              ? 0.0
              : double.tryParse(item.allowanceController.text.trim()) ?? 0.0,
          'suggested_store': item.storeController.text.trim().isEmpty
              ? null
              : item.storeController.text.trim(),
        };
      }).toList();

      final newList = await ref.read(shoppingListProvider.notifier).createShoppingList(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        deadline: null, // _deadline, // 一時的に無効化（DBカラムが存在しない）
        items: items.isNotEmpty ? items : null,
      );

      if (newList != null && mounted) {
        print('🧭 ナビゲーション開始 (goNamed使用)');
        print('📋 作成されたリストID: ${newList.id}');
        print('🔗 ルート名: shoppingListDetail');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('買い物リストを作成しました')),
        );
        
        context.goNamed(
          'shoppingListDetail',
          pathParameters: {'listId': newList.id},
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('買い物リストの作成に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

/// 買い物商品フォーム
class ShoppingItemForm {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final allowanceController = TextEditingController();
  final storeController = TextEditingController();

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    allowanceController.dispose();
    storeController.dispose();
  }
}