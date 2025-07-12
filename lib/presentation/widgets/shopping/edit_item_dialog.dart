import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../../../application/shopping/shopping_list_provider.dart';
import '../../../domain/entities/shopping_item.dart';

/// 商品編集ダイアログ
class EditItemDialog extends ConsumerStatefulWidget {
  final ShoppingItem item;

  const EditItemDialog({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends ConsumerState<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _allowanceController;
  late final TextEditingController _storeController;
  
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _priceController = TextEditingController(
      text: widget.item.estimatedPrice?.toString() ?? '',
    );
    _allowanceController = TextEditingController(
      text: widget.item.allowanceAmount.toString(),
    );
    _storeController = TextEditingController(text: widget.item.suggestedStore ?? '');
  }

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
      title: const Text('商品を編集'),
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
          text: '更新',
          onPressed: _isUpdating ? null : _updateItem,
          isLoading: _isUpdating,
        ),
      ],
    );
  }

  /// 商品を更新
  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final success = await ref.read(shoppingListProvider.notifier).updateShoppingItem(
        itemId: widget.item.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        estimatedPrice: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        allowanceAmount: _allowanceController.text.trim().isEmpty
            ? 0.0
            : double.tryParse(_allowanceController.text.trim()) ?? 0.0,
        suggestedStore: _storeController.text.trim().isEmpty
            ? null
            : _storeController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('商品を更新しました')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('商品の更新に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('商品の更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}