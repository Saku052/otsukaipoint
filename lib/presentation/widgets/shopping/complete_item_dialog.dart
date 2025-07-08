import 'package:flutter/material.dart';
import '../../../domain/entities/shopping_item.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';

/// 商品完了報告ダイアログ
class CompleteItemDialog extends StatefulWidget {
  /// 商品
  final ShoppingItem shoppingItem;
  
  /// 完了時のコールバック
  final Function(String? photoUrl, String? note) onComplete;

  const CompleteItemDialog({
    super.key,
    required this.shoppingItem,
    required this.onComplete,
  });

  @override
  State<CompleteItemDialog> createState() => _CompleteItemDialogState();
}

class _CompleteItemDialogState extends State<CompleteItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  String? _photoUrl;
  bool _isCompleting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '「${widget.shoppingItem.name}」の完了報告',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '商品を購入できましたか？\n詳細を教えてください。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 写真アップロード部分
            _buildPhotoSection(context),
            
            const SizedBox(height: 16),
            
            // メモ入力
            AppTextField(
              controller: _noteController,
              label: 'メモ（任意）',
              hint: '例: スーパーAで198円で購入しました',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // お小遣い表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '承認されると¥${widget.shoppingItem.allowanceAmount.toInt()}のお小遣いがもらえます！',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCompleting ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        AppButton(
          text: '完了報告',
          onPressed: _isCompleting ? null : _submitCompletion,
          isLoading: _isCompleting,
          size: AppButtonSize.small,
        ),
      ],
    );
  }

  /// 写真セクション
  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '商品の写真',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_photoUrl == null)
          InkWell(
            onTap: _takePicture,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '写真を撮る',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '（任意）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_photoUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => setState(() => _photoUrl = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 写真を撮る
  void _takePicture() {
    // TODO: カメラ機能を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('カメラ機能は準備中です')),
    );
    
    // デモ用のダミー写真URL
    setState(() {
      _photoUrl = 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Demo+Photo';
    });
  }

  /// 完了報告を送信
  void _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCompleting = true);

    try {
      // 少し遅延を入れてリアルな感じにする
      await Future.delayed(const Duration(seconds: 1));
      
      widget.onComplete(
        _photoUrl,
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${widget.shoppingItem.name}」の完了報告を送信しました！'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('完了報告に失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}