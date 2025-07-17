# おつかいポイント プロジェクト構造

## フォルダ構成

```
lib/
├── core/                           # コア機能
│   ├── constants/                  # 定数
│   │   └── app_constants.dart      # アプリケーション定数
│   ├── errors/                     # エラー処理
│   │   ├── exceptions.dart         # 例外クラス
│   │   └── failures.dart           # 失敗クラス
│   ├── network/                    # ネットワーク関連
│   │   └── network_info.dart       # ネットワーク情報
│   └── utils/                      # ユーティリティ
│       ├── validators.dart         # バリデーション
│       └── formatters.dart         # フォーマッター
│
├── domain/                         # ドメイン層
│   ├── entities/                   # エンティティ
│   │   ├── user.dart              # ユーザーエンティティ
│   │   ├── family.dart            # 家族エンティティ
│   │   ├── shopping_list.dart     # 買い物リストエンティティ
│   │   ├── shopping_item.dart     # 商品エンティティ
│   │   ├── allowance.dart         # お小遣いエンティティ
│   │   └── notification.dart      # 通知エンティティ
│   ├── repositories/               # リポジトリインターフェース
│   │   ├── auth_repository.dart    # 認証リポジトリ
│   │   ├── user_repository.dart    # ユーザーリポジトリ
│   │   ├── family_repository.dart  # 家族リポジトリ
│   │   ├── shopping_repository.dart # 買い物リポジトリ
│   │   ├── allowance_repository.dart # お小遣いリポジトリ
│   │   └── notification_repository.dart # 通知リポジトリ
│   └── usecases/                   # ユースケース
│       ├── auth/                   # 認証ユースケース
│       ├── shopping/               # 買い物ユースケース
│       ├── allowance/              # お小遣いユースケース
│       └── notification/           # 通知ユースケース
│
├── infrastructure/                 # インフラ層
│   ├── datasources/                # データソース
│   │   ├── auth_remote_datasource.dart
│   │   ├── user_remote_datasource.dart
│   │   ├── family_remote_datasource.dart
│   │   ├── shopping_remote_datasource.dart
│   │   ├── allowance_remote_datasource.dart
│   │   └── notification_remote_datasource.dart
│   ├── repositories/               # リポジトリ実装
│   │   ├── auth_repository_impl.dart
│   │   ├── user_repository_impl.dart
│   │   ├── family_repository_impl.dart
│   │   ├── shopping_repository_impl.dart
│   │   ├── allowance_repository_impl.dart
│   │   └── notification_repository_impl.dart
│   └── services/                   # 外部サービス
│       ├── supabase_service.dart   # Supabase設定
│       ├── realtime_service.dart   # リアルタイム通信
│       └── qr_service.dart         # QRコード生成/読み取り
│
└── presentation/                   # プレゼンテーション層
    ├── pages/                      # 画面
    │   ├── auth/                   # 認証画面
    │   │   ├── login_page.dart
    │   │   └── role_selection_page.dart
    │   ├── parent/                 # 親用画面
    │   │   ├── parent_dashboard_page.dart
    │   │   ├── create_shopping_list_page.dart
    │   │   ├── shopping_list_detail_page.dart
    │   │   ├── qr_code_page.dart
    │   │   ├── approval_page.dart
    │   │   ├── allowance_management_page.dart
    │   │   └── parent_settings_page.dart
    │   ├── child/                  # 子用画面
    │   │   ├── child_dashboard_page.dart
    │   │   ├── shopping_list_page.dart
    │   │   ├── shopping_item_detail_page.dart
    │   │   ├── allowance_balance_page.dart
    │   │   ├── allowance_history_page.dart
    │   │   ├── qr_scanner_page.dart
    │   │   └── child_settings_page.dart
    │   └── shared/                 # 共通画面
    │       ├── splash_page.dart
    │       ├── notification_page.dart
    │       └── profile_page.dart
    ├── widgets/                    # ウィジェット
    │   ├── common/                 # 共通ウィジェット
    │   │   ├── app_button.dart
    │   │   ├── app_text_field.dart
    │   │   ├── app_card.dart
    │   │   ├── loading_indicator.dart
    │   │   ├── error_widget.dart
    │   │   └── empty_state_widget.dart
    │   ├── shopping/               # 買い物関連ウィジェット
    │   │   ├── shopping_list_card.dart
    │   │   ├── shopping_item_card.dart
    │   │   ├── shopping_item_tile.dart
    │   │   └── progress_indicator.dart
    │   ├── allowance/              # お小遣い関連ウィジェット
    │   │   ├── allowance_balance_card.dart
    │   │   ├── allowance_transaction_tile.dart
    │   │   └── allowance_chart.dart
    │   ├── notification/           # 通知関連ウィジェット
    │   │   ├── notification_tile.dart
    │   │   └── notification_badge.dart
    │   └── qr/                     # QR関連ウィジェット
    │       ├── qr_code_widget.dart
    │       └── qr_scanner_widget.dart
    └── providers/                  # Riverpodプロバイダー
        ├── auth_provider.dart      # 認証プロバイダー
        ├── user_provider.dart      # ユーザープロバイダー
        ├── family_provider.dart    # 家族プロバイダー
        ├── shopping_provider.dart  # 買い物プロバイダー
        ├── allowance_provider.dart # お小遣いプロバイダー
        ├── notification_provider.dart # 通知プロバイダー
        └── theme_provider.dart     # テーマプロバイダー
```

## 主要ファイル

### ルート
- `main.dart` - アプリケーションエントリーポイント
- `app.dart` - アプリケーション設定

### テーマ・デザイン
- `lib/core/theme/app_theme.dart` - アプリテーマ設定
- `lib/core/theme/app_colors.dart` - カラーパレット
- `lib/core/theme/app_typography.dart` - タイポグラフィ

### ルーティング
- `lib/core/router/app_router.dart` - Go Routerの設定

### モデル
- `lib/infrastructure/models/` - Supabaseレスポンス用モデル

### 設定ファイル
- `pubspec.yaml` - パッケージ依存関係
- `analysis_options.yaml` - Dart静的解析設定
- `build.yaml` - ビルド設定（code generation）

## コード生成

以下のコマンドでコード生成を実行：

```bash
# モデル・プロバイダー生成
flutter packages pub run build_runner build

# 監視モードで生成
flutter packages pub run build_runner watch

# 既存ファイルを削除して生成
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## アセット

```
assets/
├── images/             # 画像ファイル
│   ├── logo.png
│   ├── placeholder.png
│   └── illustrations/
├── icons/              # アイコンファイル
│   ├── app_icon.png
│   └── custom/
└── fonts/              # フォントファイル
    ├── NotoSansJP-Regular.ttf
    ├── NotoSansJP-Bold.ttf
    └── NotoSansJP-Light.ttf
```

## 環境設定

### 環境変数
- `SUPABASE_URL` - SupabaseプロジェクトURL
- `SUPABASE_ANON_KEY` - Supabase匿名キー

### 設定ファイル
- `.env` - 環境変数ファイル（gitignoreに追加）
- `android/app/build.gradle` - Android設定
- `ios/Runner/Info.plist` - iOS設定

## 開発ガイドライン

### 命名規則
- **ファイル名**: snake_case
- **クラス名**: PascalCase
- **変数・関数名**: camelCase
- **定数**: UPPER_SNAKE_CASE

### コード規約
- Dart公式スタイルガイドに従う
- flutter_lintsの推奨ルールを適用
- 全ての公開メソッドにドキュメントコメントを記述

### テスト
- 単体テスト: `test/unit/`
- ウィジェットテスト: `test/widget/`
- 統合テスト: `test/integration/`