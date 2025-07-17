import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../../../application/shopping/shopping_list_provider.dart';
import '../../../domain/entities/shopping_list.dart';

/// 買い物リスト編集ダイアログ
class EditShoppingListDialog extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;

  const EditShoppingListDialog({
    super.key,
    required this.shoppingList,
  });

  @override
  ConsumerState<EditShoppingListDialog> createState() => _EditShoppingListDialogState();
}

class _EditShoppingListDialogState extends ConsumerState<EditShoppingListDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.shoppingList.title);
    _descriptionController = TextEditingController(text: widget.shoppingList.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('買い物リストを編集'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'リスト名',
                hint: '例: 今週の買い物',
                prefixIcon: Icons.shopping_cart,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'リスト名を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _descriptionController,
                label: '説明（任意）',
                hint: '例: 今週必要な食材と日用品',
                prefixIcon: Icons.description,
                maxLines: 3,
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
          onPressed: _isUpdating ? null : _updateShoppingList,
          isLoading: _isUpdating,
        ),
      ],
    );
  }

  /// 買い物リストを更新
  Future<void> _updateShoppingList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final success = await ref.read(shoppingListProvider.notifier).updateShoppingList(
        listId: widget.shoppingList.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('買い物リストを更新しました')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('買い物リストの更新に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('買い物リストの更新に失敗しました: $e'),
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