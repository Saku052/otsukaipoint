# アカウント削除機能 実装仕様書

## 📋 概要

このドキュメントは、おつかいポイントアプリのアカウント削除機能の実装仕様について説明しています。

### 主な特徴
- 30日間の猶予期間付きソフトデリート
- 家族関係を考慮した安全な削除処理
- 詳細な監査ログとセキュリティ対策
- データ復旧機能の提供

## 🏗️ アーキテクチャ

### システム構成
```
┌─────────────────────┐
│   フロントエンド      │
│  (Flutter/Dart)     │
├─────────────────────┤
│    サービス層        │
│ AccountDeletionService│
├─────────────────────┤
│   データベース層      │
│  (PostgreSQL/RLS)   │
└─────────────────────┘
```

## 🗄️ データベース設計

### 新規追加テーブル

#### account_deletion_logs
```sql
CREATE TABLE account_deletion_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    user_email TEXT NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    family_id UUID,
    deletion_reason TEXT,
    deletion_type VARCHAR(20) NOT NULL CHECK (deletion_type IN ('soft', 'hard', 'cancelled')),
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT,
    additional_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 既存テーブルへの追加カラム

#### user_profiles
```sql
ALTER TABLE user_profiles 
ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE NULL,
ADD COLUMN deletion_reason TEXT NULL,
ADD COLUMN scheduled_hard_delete_at TIMESTAMP WITH TIME ZONE NULL,
ADD COLUMN deleted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
```

### ストアドファンクション

#### soft_delete_user_account
- ユーザーアカウントのソフトデリート実行
- 家族関係の処理
- 30日後のハードデリート予約

#### restore_deleted_account
- 削除されたアカウントの復旧
- 猶予期間内の制限チェック

#### hard_delete_user_account
- アカウントの完全削除
- 関連データのカスケード削除

## 🚀 API仕様

### AccountDeletionService

#### softDeleteAccount
```dart
Future<AccountDeletionResult> softDeleteAccount({
  required String userId,
  required String password,
  String? reason,
  String? ipAddress,
  String? userAgent,
})
```

**処理フロー:**
1. パスワード再認証
2. ユーザー情報取得
3. 家族関係の影響チェック
4. ソフトデリート実行
5. 監査ログ記録

#### restoreAccount
```dart
Future<AccountRestorationResult> restoreAccount({
  required String userId,
  required String password,
})
```

**処理フロー:**
1. パスワード再認証
2. 復旧可能性チェック
3. アカウント復旧実行
4. ログ記録

## 🎨 UI/UX設計

### 画面構成

#### 1. アカウント削除画面 (`AccountDeletionPage`)
- **警告カード**: 削除の影響と注意事項
- **削除情報カード**: 削除されるデータの詳細
- **理由選択**: 削除理由のチップ選択
- **パスワード確認**: セキュリティチェック
- **最終確認**: チェックボックス同意

#### 2. 削除完了画面 (`AccountDeletedPage`)
- **完了メッセージ**: 削除処理の完了通知
- **スケジュール表示**: 完全削除予定日
- **家族影響表示**: 影響を受ける家族メンバー
- **復旧情報**: 30日間の復旧可能期間

#### 3. アカウント復旧画面 (`AccountRestorePage`)
- **復旧情報**: 復旧可能な内容の説明
- **残り時間**: 復旧可能期間のカウントダウン
- **パスワード確認**: 本人確認
- **サポート情報**: 問い合わせ方法

### デザインガイドライン

#### カラーパレット
- **警告**: `Colors.red.shade50` / `Colors.red.shade700`
- **情報**: `Colors.blue.shade50` / `Colors.blue.shade700`
- **成功**: `Colors.green.shade50` / `Colors.green.shade700`
- **注意**: `Colors.orange.shade50` / `Colors.orange.shade700`

#### アイコン使用
- `Icons.warning_amber_rounded` - 重要な警告
- `Icons.delete_forever` - アカウント削除
- `Icons.restore` - データ復旧
- `Icons.family_restroom` - 家族への影響

## 🛡️ セキュリティ

### 認証・認可
- **パスワード再認証**: 削除・復旧時の必須確認
- **セッション管理**: 削除後の即座なログアウト
- **監査ログ**: すべての操作の詳細記録

### データ保護
- **ソフトデリート**: 30日間のデータ保持
- **カスケード処理**: 関連データの適切な処理
- **プライバシー保護**: 個人情報の安全な削除

### アクセス制御
- **本人確認**: パスワード入力による認証
- **操作制限**: 削除済みユーザーのアクセス制御
- **権限管理**: 家族メンバーの適切な処理

## 🧪 テスト戦略

### 単体テスト
- データモデルの検証
- JSONシリアライゼーション
- エラーハンドリング

### 統合テスト
- データベース操作の検証
- API呼び出しのテスト
- 認証フローの確認

### E2Eテスト
- 削除フロー全体の動作確認
- 復旧フローの検証
- エラーケースの処理

## 📊 監視・分析

### メトリクス収集
- 削除理由の統計
- 復旧率の追跡
- エラー発生率の監視

### ログ記録
- 削除操作の詳細ログ
- セキュリティイベント
- パフォーマンス指標

## 🚀 デプロイメント

### データベースマイグレーション
```bash
# マイグレーション実行
supabase migration apply 006_account_deletion_support.sql
```

### 設定項目
- **削除猶予期間**: 30日（デフォルト）
- **ログ保持期間**: 1年
- **復旧通知**: メール通知設定

## 🔄 運用・保守

### 定期処理
- **自動ハードデリート**: 期限切れアカウントの完全削除
- **ログクリーンアップ**: 古い監査ログの削除
- **統計レポート**: 削除理由の分析レポート

### 緊急時対応
- **削除停止**: 緊急時の削除処理停止
- **データ復旧**: バックアップからの復旧手順
- **サポート対応**: ユーザーサポートの手順

## 📞 サポート

### ユーザーサポート
- **メール**: support@otsukaipoint.jp
- **FAQ**: アプリ内ヘルプセンター
- **復旧サポート**: 30日間の復旧支援

### 開発者向け
- **API仕様書**: この仕様書
- **テストガイド**: テスト実行手順
- **デバッグ情報**: ログ分析方法

## 📝 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|-----------|----------|---------|
| 2025-07-13 | 1.0.0 | 初版作成 | Claude |

## 🎯 今後の拡張

### 予定機能
- **削除予約**: 指定日時での自動削除
- **部分削除**: 特定データのみの削除
- **一括操作**: 管理者による一括削除

### 改善点
- **UI/UX**: より直感的な操作フロー
- **パフォーマンス**: 大量データの処理最適化
- **国際化**: 多言語対応

---

**注意**: この仕様書は実装ガイドラインです。実際の運用では、法的要件やプライバシー規制への準拠を確認してください。