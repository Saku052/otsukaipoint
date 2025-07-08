# Supabaseデータベース設定

このディレクトリには、おつかいポイントアプリのデータベースマイグレーションファイルが含まれています。

## マイグレーションファイル

### 001_initial_setup.sql
- 基本的な家族管理とお小遣いシステムのテーブル作成
- families, family_members, allowance_balances, allowance_transactions
- RLS（Row Level Security）ポリシーの設定
- インデックスとトリガーの作成

### 002_shopping_tables.sql  
- 買い物リスト関連のテーブル作成
- shopping_lists, shopping_items, notifications, notification_settings
- RLSポリシーの設定

### 003_users_extension.sql
- ユーザープロファイル拡張
- 便利なビューと関数の作成
- 統計情報取得関数

## セットアップ手順

### 1. Supabase CLIのインストール
```bash
npm install -g supabase
```

### 2. Supabaseプロジェクトの初期化
```bash
# プロジェクトルートで実行
supabase init

# ローカル開発環境の起動
supabase start
```

### 3. マイグレーションの実行
```bash
# すべてのマイグレーションを実行
supabase db reset

# または個別に実行
supabase db push
```

### 4. 本番環境への適用
```bash
# Supabaseプロジェクトにリンク
supabase link --project-ref <your-project-ref>

# 本番環境にマイグレーションを適用
supabase db push
```

## 環境変数設定

アプリで使用する環境変数を設定してください：

```bash
# .env.local ファイルを作成
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## データベース構造

### 主要テーブル関係
```
auth.users (Supabase標準)
├── user_profiles (ユーザー詳細情報)
├── family_members (家族メンバー関係)
│   └── families (家族情報)
│       └── shopping_lists (買い物リスト)
│           └── shopping_items (買い物アイテム)
├── allowance_balances (お小遣い残高)
└── allowance_transactions (お小遣い取引履歴)
```

### セキュリティ
- すべてのテーブルでRLS（Row Level Security）が有効
- 家族メンバーのみがデータにアクセス可能
- 子どもは自分のデータと家族のデータのみ閲覧可能
- 親は家族全体のデータを管理可能

## トラブルシューティング

### よくある問題

1. **マイグレーション失敗**
   ```bash
   # ローカルDBをリセット
   supabase db reset
   ```

2. **権限エラー**
   - RLSポリシーを確認
   - ユーザーが適切な家族に所属しているか確認

3. **接続エラー**
   - 環境変数が正しく設定されているか確認
   - SupabaseプロジェクトのURLとキーを確認

## 開発時のヒント

### ローカル開発
```bash
# ローカルSupabaseの状態確認
supabase status

# ローカルダッシュボードにアクセス
# http://localhost:54323
```

### データベース操作
```bash
# SQLエディタでクエリ実行
supabase db shell

# スキーマの差分確認
supabase db diff
```

### サンプルデータ
開発時にサンプルデータを作成したい場合は、`insert_sample_data()`関数を使用してください（開発環境のみ）。