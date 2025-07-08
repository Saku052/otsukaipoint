import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../application/auth/auth_provider.dart';
import '../../../domain/entities/user.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('役割を選択'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'あなたの役割を選択してください',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // 親の役割カード
            _RoleCard(
              icon: Icons.supervisor_account,
              title: '親',
              description: 'お買い物リストを作成し、\n子どもの お使いを管理します',
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _selectRole(context, ref, 'parent'),
            ),
            
            const SizedBox(height: 24),
            
            // 子の役割カード
            _RoleCard(
              icon: Icons.child_care,
              title: '子ども',
              description: 'お買い物リストを確認し、\nお使いを完了してお小遣いをもらいます',
              color: Theme.of(context).colorScheme.secondary,
              onTap: () => _selectRole(context, ref, 'child'),
            ),
            
            const SizedBox(height: 48),
            
            Text(
              '後から変更することもできます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, WidgetRef ref, String role) async {
    final authNotifier = ref.read(authProvider.notifier);
    
    try {
      // ユーザーロールを更新
      final userRole = role == 'parent' ? UserRole.parent : UserRole.child;
      await authNotifier.updateProfile(role: userRole);
      
      // 適切なダッシュボードに遷移
      if (context.mounted) {
        if (role == 'parent') {
          context.go(AppRouter.parentDashboard);
        } else {
          context.go(AppRouter.childDashboard);
        }
      }
    } catch (e) {
      // エラーハンドリング
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ロールの更新に失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}