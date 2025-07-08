// アプリケーション定数
class AppConstants {
  // アプリ情報
  static const String appName = 'おつかいポイント';
  static const String appVersion = '1.0.0';
  
  // 制限値
  static const int maxParentsPerFamily = 2;
  static const int maxChildrenPerFamily = 2;
  static const int maxShoppingListsPerFamily = 50;
  static const int maxItemsPerShoppingList = 100;
  
  // QRコード
  static const Duration qrCodeExpiration = Duration(minutes: 5);
  static const String qrCodePrefix = 'otsukaipoint://family/';
  
  // 通知
  static const String notificationChannelId = 'otsukaipoint_notifications';
  static const String notificationChannelName = 'おつかいポイント通知';
  
  // データ保持期間
  static const Duration deletedDataRetention = Duration(days: 7);
  static const Duration nameChangeInterval = Duration(days: 7);
  
  // ページネーション
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // 画像
  static const double maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // 通貨
  static const String currencySymbol = '¥';
  static const int currencyDecimalPlaces = 0;
  
  // アニメーション
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // データベース
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  // エラーメッセージ
  static const String networkError = 'ネットワークエラーが発生しました';
  static const String serverError = 'サーバーエラーが発生しました';
  static const String unknownError = '予期しないエラーが発生しました';
  static const String authError = '認証エラーが発生しました';
  
  // 成功メッセージ
  static const String loginSuccess = 'ログインしました';
  static const String logoutSuccess = 'ログアウトしました';
  static const String itemCompletedSuccess = 'お使いを完了しました';
  static const String itemApprovedSuccess = 'お使いを承認しました';
  static const String itemRejectedSuccess = 'お使いを拒否しました';
  static const String shoppingListCreatedSuccess = 'お買い物リストを作成しました';
  static const String familyConnectedSuccess = '家族と連携しました';
  
  // 確認メッセージ
  static const String deleteConfirmation = '本当に削除しますか？';
  static const String logoutConfirmation = 'ログアウトしますか？';
  static const String approveConfirmation = 'この お使いを承認しますか？';
  static const String rejectConfirmation = 'この お使いを拒否しますか？';
  
  // プライベートコンストラクタ
  AppConstants._();
}