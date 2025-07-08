import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../../../application/shopping/shopping_list_provider.dart';

/// 商品追加ダイアログ
class AddItemDialog extends ConsumerStatefulWidget {
  final String shoppingListId;

  const AddItemDialog({
    super.key,
    required this.shoppingListId,
  });

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _allowanceController = TextEditingController();
  final _storeController = TextEditingController();
  
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _allowanceController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('商品を追加'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                label: '商品名',
                hint: '例: 牛乳',
                prefixIcon: Icons.shopping_cart,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '商品名を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _descriptionController,
                label: '説明（任意）',
                hint: '例: 1リットル、低脂肪',
                prefixIcon: Icons.description,
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      label: '予想価格（任意）',
                      hint: '例: 200',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return '正しい金額を入力してください';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: AppTextField(
                      controller: _allowanceController,
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
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _storeController,
                label: '推奨店舗（任意）',
                hint: '例: スーパーA',
                prefixIcon: Icons.store,
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          text: 'キャンセル',
          type: AppButtonType.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: '追加',
          onPressed: _isAdding ? null : _addItem,
          isLoading: _isAdding,
        ),
      ],
    );
  }

  /// 商品を追加
  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);

    try {
      final itemData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'estimated_price': _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        'allowance_amount': _allowanceController.text.trim().isEmpty
            ? 0.0
            : double.tryParse(_allowanceController.text.trim()) ?? 0.0,
        'suggested_store': _storeController.text.trim().isEmpty
            ? null
            : _storeController.text.trim(),
      };

      await ref.read(shoppingListProvider.notifier).addShoppingItem(
        shoppingListId: widget.shoppingListId,
        name: itemData['name'] as String,
        description: itemData['description'] as String?,
        estimatedPrice: itemData['estimated_price'] as double?,
        allowanceAmount: itemData['allowance_amount'] as double,
        suggestedStore: itemData['suggested_store'] as String?,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品を追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('商品の追加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }
}