import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../application/auth/auth_provider.dart';
import '../../../../application/family/family_provider.dart';
import '../../../../domain/providers/usecase_providers.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/loading_widget.dart';

/// 家族メンバー管理画面
class FamilyMembersPage extends ConsumerStatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  ConsumerState<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends ConsumerState<FamilyMembersPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final familyState = ref.watch(familyProvider);

    return AppScaffold(
      title: '家族メンバー管理',
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await ref.read(familyProvider.notifier).getCurrentFamily();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInviteSection(context),
              const SizedBox(height: 24),
              _buildMembersSection(context, familyState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '新しいメンバーを招待',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '子をアプリに招待して家族として追加できます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'QRコードを生成',
              onPressed: () => context.push('/parent/qr-code'),
              icon: Icons.qr_code,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, familyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '現在のメンバー',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (familyState.isLoading)
          const Center(child: LoadingWidget())
        else if (familyState.currentFamily?.members.isEmpty ?? true)
          _buildEmptyMembersCard()
        else
          ...familyState.currentFamily!.members.map((member) => 
              _buildMemberCard(member, familyState.currentFamily!.createdBy)),
      ],
    );
  }

  Widget _buildEmptyMembersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'メンバーがいません',
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
    );
  }

  Widget _buildMemberCard(member, String createdBy) {
    final isOwner = member.userId == createdBy;
    final isChild = member.role == 'child';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isChild 
              ? Colors.orange.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            isChild ? Icons.child_care : Icons.person,
            color: isChild ? Colors.orange[700] : Colors.blue[700],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.userName ?? 'ユーザー',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'オーナー',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              member.role == 'parent' ? '親アカウント' : '子アカウント',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '参加日: ${_formatDate(member.joinedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
            ),
            if (!member.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '停止中',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
          ],
        ),
        trailing: isChild && !isOwner 
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  if (member.isActive)
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('一時停止'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'reactivate',
                      child: Row(
                        children: [
                          Icon(Icons.play_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('再有効化'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _handleMemberAction(String action, member) {
    switch (action) {
      case 'suspend':
        _showSuspendDialog(member);
        break;
      case 'reactivate':
        _showReactivateDialog(member);
        break;
      case 'remove':
        _showRemoveDialog(member);
        break;
    }
  }

  void _showSuspendDialog(member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを一時停止'),
        content: Text(
          '${member.userName ?? "このメンバー"}のアカウントを一時停止しますか？\n\n一時停止中はアプリにログインできなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _suspendMember(member.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('一時停止'),
          ),
        ],
      ),
    );
  }

  void _showReactivateDialog(member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを再有効化'),
        content: Text(
          '${member.userName ?? "このメンバー"}のアカウントを再有効化しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _reactivateMember(member.id);
            },
            child: const Text('再有効化'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text(
          '${member.userName ?? "このメンバー"}を家族から削除しますか？\n\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeMember(member.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _suspendMember(String memberId) async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ユーザー情報が取得できません');

      final manageFamilyUseCase = ref.read(manageFamilyUseCaseProvider);
      await manageFamilyUseCase.suspendChildAccount(
        memberId: memberId,
        suspendedBy: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メンバーを一時停止しました'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // 家族情報を再読み込み
        ref.read(familyProvider.notifier).getCurrentFamily();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('一時停止に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reactivateMember(String memberId) async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('ユーザー情報が取得できません');

      final manageFamilyUseCase = ref.read(manageFamilyUseCaseProvider);
      await manageFamilyUseCase.reactivateChildAccount(
        memberId: memberId,
        reactivatedBy: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メンバーを再有効化しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 家族情報を再読み込み
        ref.read(familyProvider.notifier).getCurrentFamily();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再有効化に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    setState(() => _isLoading = true);

    try {
      // TODO: メンバー削除機能の実装
      await Future.delayed(const Duration(seconds: 1)); // 仮の処理

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メンバー削除機能は実装予定です'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}