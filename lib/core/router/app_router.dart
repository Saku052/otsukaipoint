import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../application/auth/auth_guard.dart';
import '../../presentation/pages/shared/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/role_selection_page.dart';
import '../../presentation/pages/parent/parent_dashboard_page.dart';
import '../../presentation/pages/parent/create_shopping_list_page.dart';
import '../../presentation/pages/parent/shopping_list_detail_page.dart';
import '../../presentation/pages/parent/shopping_list_page.dart';
import '../../presentation/pages/child/child_dashboard_page.dart';
import '../../presentation/pages/child/child_shopping_list_detail_page.dart';
import '../../presentation/pages/child/child_allowance_page.dart';
import '../../presentation/pages/child/allowance_history_page.dart';
import '../../presentation/pages/parent/approval_page.dart';
import '../../presentation/pages/parent/qr_code_page.dart';
import '../../presentation/pages/child/qr_scanner_page.dart';
import '../../presentation/pages/shared/notification_page.dart';
import '../../presentation/pages/parent/settings/parent_settings_page.dart';
import '../../presentation/pages/parent/settings/notification_settings_page.dart';
import '../../presentation/pages/parent/settings/allowance_settings_page.dart';
import '../../presentation/pages/parent/settings/family_members_page.dart';
import '../../presentation/pages/parent/settings/privacy_settings_page.dart';
import '../../presentation/pages/child/settings/child_settings_page.dart';
import '../../presentation/pages/child/settings/child_notification_settings_page.dart';
import '../../presentation/pages/parent/allowance_adjustment_page.dart';
import '../../presentation/pages/parent/allowance_history_page.dart' as parent;
import '../../presentation/pages/auth/account_deleted_page.dart';
import '../../presentation/pages/auth/account_restore_page.dart';
import '../../presentation/pages/parent/settings/account_deletion_page.dart';

/// アプリケーションのルーティング設定
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String roleSelection = '/role-selection';
  static const String parentDashboard = '/parent/dashboard';
  static const String childDashboard = '/child/dashboard';
  static const String createShoppingList = '/parent/create-list';
  static const String shoppingLists = '/parent/shopping-lists';
  static const String shoppingListDetail = '/parent/list/:listId';
  static const String qrCode = '/parent/qr-code';
  static const String approval = '/parent/approval';
  static const String allowanceManagement = '/parent/allowance';
  static const String parentSettings = '/parent/settings';
  static const String childShoppingLists = '/child/shopping-lists';
  static const String childShoppingListDetail = '/child/list/:listId';
  static const String childShoppingItemDetail = '/child/item/:itemId';
  static const String allowanceBalance = '/child/allowance';
  static const String allowanceHistory = '/child/allowance/history';
  static const String qrScanner = '/child/qr-scanner';
  static const String childSettings = '/child/settings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String accountDeleted = '/account-deleted';
  static const String accountRestore = '/account-restore';
  static const String accountDeletion = '/parent/settings/account-deletion';

  static final GoRouter _router = GoRouter(
    initialLocation: splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const AnonymousGuard(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: roleSelection,
        name: 'roleSelection',
        builder: (context, state) => const AuthGuard(
          child: RoleSelectionPage(),
        ),
      ),
      
      // Parent Routes
      GoRoute(
        path: parentDashboard,
        name: 'parentDashboard',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: ParentDashboardPage(),
        ),
      ),
      GoRoute(
        path: createShoppingList,
        name: 'createShoppingList',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: CreateShoppingListPage(),
        ),
      ),
      GoRoute(
        path: shoppingLists,
        name: 'shoppingLists',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: ShoppingListPage(),
        ),
      ),
      GoRoute(
        path: shoppingListDetail,
        name: 'shoppingListDetail',
        builder: (context, state) {
          final listId = state.pathParameters['listId']!;
          return RoleGuard(
            allowedRoles: ['parent'],
            child: ShoppingListDetailPage(listId: listId),
          );
        },
      ),
      GoRoute(
        path: qrCode,
        name: 'qrCode',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: QrCodePage(),
        ),
      ),
      GoRoute(
        path: approval,
        name: 'approval',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: ApprovalPage(),
        ),
      ),
      GoRoute(
        path: allowanceManagement,
        name: 'allowanceManagement',
        builder: (context, state) => const Placeholder(), // TODO: AllowanceManagementPage(),
      ),
      GoRoute(
        path: parentSettings,
        name: 'parentSettings',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: ParentSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/parent/settings/notifications',
        name: 'parentNotificationSettings',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: NotificationSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/parent/settings/allowance',
        name: 'parentAllowanceSettings',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: AllowanceSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/parent/settings/family-members',
        name: 'familyMembers',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: FamilyMembersPage(),
        ),
      ),
      GoRoute(
        path: '/parent/allowance/adjust',
        name: 'allowanceAdjustment',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: AllowanceAdjustmentPage(),
        ),
      ),
      GoRoute(
        path: '/parent/allowance/adjust/:childId',
        name: 'allowanceAdjustmentWithChild',
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          return RoleGuard(
            allowedRoles: ['parent'],
            child: AllowanceAdjustmentPage(childId: childId),
          );
        },
      ),
      GoRoute(
        path: '/parent/allowance/history',
        name: 'parentAllowanceHistory',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: parent.AllowanceHistoryPage(),
        ),
      ),
      GoRoute(
        path: '/parent/allowance/history/:childId',
        name: 'parentAllowanceHistoryWithChild',
        builder: (context, state) {
          final childId = state.pathParameters['childId']!;
          return RoleGuard(
            allowedRoles: ['parent'],
            child: parent.AllowanceHistoryPage(childId: childId),
          );
        },
      ),
      GoRoute(
        path: '/parent/settings/privacy',
        name: 'parentPrivacySettings',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: PrivacySettingsPage(),
        ),
      ),
      GoRoute(
        path: accountDeletion,
        name: 'accountDeletion',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['parent'],
          child: AccountDeletionPage(),
        ),
      ),
      
      // Child Routes
      GoRoute(
        path: childDashboard,
        name: 'childDashboard',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['child'],
          child: ChildDashboardPage(),
        ),
      ),
      GoRoute(
        path: childShoppingLists,
        name: 'childShoppingLists',
        builder: (context, state) => const Placeholder(), // TODO: ShoppingListPage(),
      ),
      GoRoute(
        path: childShoppingListDetail,
        name: 'childShoppingListDetail',
        builder: (context, state) {
          final listId = state.pathParameters['listId']!;
          return RoleGuard(
            allowedRoles: ['child'],
            child: ChildShoppingListDetailPage(listId: listId),
          );
        },
      ),
      GoRoute(
        path: childShoppingItemDetail,
        name: 'childShoppingItemDetail',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return const Placeholder(); // TODO: ShoppingItemDetailPage(itemId: itemId),
        },
      ),
      GoRoute(
        path: allowanceBalance,
        name: 'allowanceBalance',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['child'],
          child: ChildAllowancePage(),
        ),
      ),
      GoRoute(
        path: allowanceHistory,
        name: 'childAllowanceHistory',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['child'],
          child: AllowanceHistoryPage(),
        ),
      ),
      GoRoute(
        path: qrScanner,
        name: 'qrScanner',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['child'],
          child: QrScannerPage(),
        ),
      ),
      GoRoute(
        path: childSettings,
        name: 'childSettings',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['child'],
          child: ChildSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/child/settings/notifications',
        name: 'childNotificationSettings',
        builder: (context, state) => const RoleGuard(
          allowedRoles: ['child'],
          child: ChildNotificationSettingsPage(),
        ),
      ),
      
      // Shared Routes
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const AuthGuard(
          child: NotificationPage(),
        ),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const Placeholder(), // TODO: ProfilePage(),
      ),
      
      // Account deletion and restoration routes
      GoRoute(
        path: accountDeleted,
        name: 'accountDeleted',
        builder: (context, state) {
          final scheduledDeleteAtParam = state.uri.queryParameters['scheduledDeleteAt'];
          
          if (scheduledDeleteAtParam == null) {
            return const Scaffold(
              body: Center(
                child: Text('無効なアクセスです'),
              ),
            );
          }
          
          final scheduledDeleteAt = DateTime.parse(scheduledDeleteAtParam);
          
          return AccountDeletedPage(
            scheduledDeleteAt: scheduledDeleteAt,
            familyImpact: null,
          );
        },
      ),
      GoRoute(
        path: accountRestore,
        name: 'accountRestore',
        builder: (context, state) => const AccountRestorePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'ページが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'お探しのページは存在しないか、移動した可能性があります。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(splash),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;
}