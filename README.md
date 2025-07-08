# 🛒 おつかいポイント (Otsukai Point)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Material Design](https://img.shields.io/badge/Material%20Design-757575?style=for-the-badge&logo=material-design&logoColor=white)

**親子で楽しむお買い物アプリ**  
*A family shopping app that helps children learn financial responsibility*

[📱 Features](#-key-features) • [🏗️ Architecture](#-architecture--design) • [🎯 Demo](#-ui--ux-highlights)

</div>

---

## 📋 Project Overview

おつかいポイントは、親子間でのお買い物リスト共有とお小遣い管理を通じて、子供の金銭感覚を育む教育的なモバイルアプリケーションです。Flutter + Supabaseのモダンな技術スタックで構築され、リアルタイム通信と安全なQRコード連携機能を実装しています。

### 🎯 Core Value
- **教育的価値**: 子供が実際の買い物体験を通じて金銭感覚を学習
- **家族の絆**: QRコード連携による安全で簡単な親子アカウント管理
- **技術的革新**: Clean Architecture + Riverpodによる保守性の高い設計

---

## ✨ Key Features

### 👨‍👩‍👧‍👦 Family Account Management
- **Multi-Role System**: 親（最大2名）・子（最大2名）の役割別アカウント
- **Google OAuth**: Supabase Authによる安全な認証システム
- **QR Code Linking**: 5分間有効期限付きワンタイムQRコードで親子連携

### 🛍️ Smart Shopping List
- **Real-time Sync**: Supabase Realtimeによる瞬時のデータ同期
- **Task Distribution**: 複数の子供が異なる商品を同時に担当可能
- **Flexible Settings**: 商品ごと個別 or 一律のお小遣い設定

### 💰 Allowance Management System
- **Approval Workflow**: 親による承認・拒否システムで安全性を確保
- **Transaction History**: 詳細な獲得・使用履歴の管理機能
- **Balance Control**: 親による残高調整（追加・減額）機能

### 🔔 Advanced Notification System
- **Multi-Channel**: アプリ内通知 + Supabase Edge Functions
- **Event-Driven**: 商品追加、完了報告、承認通知のリアルタイム配信
- **Custom Settings**: ユーザー別の通知オン/オフ設定

---

## 🏗️ Architecture & Design

### Clean Architecture Implementation
```
📁 lib/
├── 🎯 domain/                    # ビジネスロジック層
│   ├── entities/                 # コアエンティティ
│   │   ├── user.dart            # ユーザー（親・子）
│   │   ├── family.dart          # 家族グループ
│   │   ├── shopping_list.dart   # 買い物リスト
│   │   ├── shopping_item.dart   # 商品情報
│   │   └── allowance.dart       # お小遣い管理
│   ├── repositories/            # リポジトリインターフェース
│   └── usecases/               # ビジネスユースケース
├── 🏗️ infrastructure/            # インフラ層
│   ├── datasources/            # Supabase API統合
│   ├── repositories/           # リポジトリ実装
│   └── services/              # 外部サービス連携
└── 🎨 presentation/             # プレゼンテーション層
    ├── pages/                  # 画面実装
    │   ├── parent/            # 親用画面（ダッシュボード、承認管理）
    │   ├── child/             # 子用画面（リスト表示、完了報告）
    │   └── shared/            # 共通画面
    ├── widgets/               # 再利用可能コンポーネント
    └── providers/             # Riverpod状態管理
```

### State Management Strategy
- **Riverpod 2.5+**: 依存性注入とリアクティブプログラミング
- **Code Generation**: riverpod_generatorによる型安全な状態管理
- **Provider Pattern**: テスト容易性を考慮した疎結合設計

### Material Design 3 Integration
- **Dynamic Theming**: システム設定に応じた動的カラーテーマ
- **Adaptive Layout**: デバイス特性（スマートフォン・タブレット）対応
- **Accessibility**: WCAG準拠のアクセシブルデザイン

---

## 🔧 Technical Stack

### Core Technologies
- **Frontend**: Flutter 3.8+ / Dart 3.0+
- **Backend**: Supabase (PostgreSQL + Realtime + Auth + Edge Functions)
- **State Management**: Riverpod + Code Generation
- **Navigation**: Go Router 14.6+

### Key Dependencies
```yaml
# 状態管理 & アーキテクチャ
flutter_riverpod: ^2.5.1        # メイン状態管理
riverpod_annotation: ^2.3.5     # コード生成アノテーション
freezed: ^2.5.7                 # イミュータブルクラス生成

# バックエンド統合
supabase_flutter: ^2.7.0        # Supabase統合
flutter_dotenv: ^5.1.0          # 環境変数管理

# UI/UX
go_router: ^14.6.1              # 宣言的ナビゲーション
flutter_svg: ^2.0.14           # SVGサポート
shimmer: ^3.0.0                 # ローディングアニメーション

# QRコード機能
qr_flutter: ^4.1.0             # QRコード生成

# ユーティリティ
dartz: ^0.10.1                  # 関数型プログラミング
equatable: ^2.0.7               # 値オブジェクト比較
intl: ^0.19.0                   # 国際化対応
```

### Database Architecture
- **PostgreSQL**: Supabaseマネージドデータベース
- **Row Level Security (RLS)**: 家族単位でのデータアクセス制御
- **Real-time Subscriptions**: WebSocketベースの即座のデータ同期
- **Migration Management**: バージョン管理されたスキーマ進化

---

## 🎯 UI & UX Highlights

### Parent Interface
- **統合ダッシュボード**: 子供の進捗とお小遣い残高を一覧表示
- **リスト作成**: 直感的な商品追加とお小遣い設定
- **QRコード生成**: セキュアな親子アカウント連携
- **承認管理**: ワンタップでの完了報告承認・拒否

### Child Interface  
- **ビジュアル重視**: 子供にも分かりやすいカード型UI
- **進捗表示**: リアルタイムの完了状況とお小遣い獲得予定
- **簡単操作**: タップ一つでの完了報告機能
- **残高確認**: 現在のお小遣い残高と履歴表示

### Responsive Design
- **Cross-Platform**: iOS・Android・タブレット完全対応
- **Dynamic Layouts**: 画面サイズに応じた最適なレイアウト
- **Dark Mode**: システム設定連動のダーク/ライトテーマ

---

## 🧪 Quality Assurance & Testing

### Testing Strategy
- **Unit Tests**: ビジネスロジックの完全カバレッジ
- **Widget Tests**: UI コンポーネントの動作検証  
- **Integration Tests**: エンドツーエンドユーザーフロー

### Code Quality Tools
- **Flutter Lints**: Dart公式の静的解析ルール
- **Build Runner**: 自動コード生成によるボイラープレート削減
- **Analysis Options**: プロジェクト固有の品質基準設定

### Performance Metrics
- **App Launch**: 3秒以内の初期画面表示
- **Memory Management**: 効率的なメモリ使用とリーク防止
- **Network Optimization**: Supabaseクエリの最適化

---

## 🚀 Development Workflow

### Environment Setup
```bash
# プロジェクトクローン
git clone https://github.com/soraharada/otsukaipoint.git
cd otsukaipoint

# 依存関係インストール
flutter pub get

# コード生成実行
flutter packages pub run build_runner build

# 開発サーバー起動
flutter run
```

### Database Setup
```bash
# Supabase ローカル環境構築
npx supabase init
npx supabase start

# マイグレーション実行
npx supabase db reset
```

### Code Generation
```bash
# 監視モードでの自動生成
flutter packages pub run build_runner watch

# 既存ファイル削除して再生成
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

## 🏆 Technical Achievements

### Scalability & Architecture
- **Clean Architecture**: 関心の分離による高い保守性
- **Dependency Injection**: Riverpodによるテスタブルな設計
- **Code Generation**: 型安全性とDeveloper Experience向上

### Security Implementation
- **OAuth 2.0**: Google認証による堅牢なユーザー管理
- **RLS Policies**: PostgreSQLレベルでのマルチテナント対応
- **QR Security**: タイムスタンプベースの期限切れ管理

### Performance Optimization
- **Lazy Loading**: 必要時のみデータ取得による高速化
- **State Caching**: Riverpodキャッシュによる不要な再計算防止
- **Asset Optimization**: SVG使用による軽量な画像リソース

---

## 📈 Future Roadmap

### Phase 2 Features
- 📸 **Photo Verification**: 購入証明写真のアップロード機能
- 📊 **Analytics Dashboard**: 家計簿機能と支出分析
- 🎮 **Gamification**: 達成バッジとレベルシステム
- 💬 **Family Chat**: 親子間のメッセージ機能

### Technical Enhancements
- 🌐 **Offline Support**: SQLiteローカルキャッシュ
- 📱 **Push Notifications**: FCMによるプッシュ通知
- 🔄 **Background Sync**: バックグラウンドデータ同期
- 🌍 **Internationalization**: 多言語対応（英語）

---

## 👨‍💻 Project Information

**開発期間**: 2025年6月 - 現在進行中  
**開発規模**: ~15,000行（Dart）+ データベース設計  
**主要技術**: Flutter, Supabase, PostgreSQL, Material Design 3  
**アーキテクチャ**: Clean Architecture + Riverpod + Code Generation  

### Development Highlights
- **Modern Tech Stack**: 最新のFlutter 3.8+とSupabase統合
- **Production Ready**: 実際の家庭での使用を想定した実用的設計  
- **Educational Value**: エンジニアリング技術と社会的価値の両立
- **Scalable Design**: 将来の機能拡張を見据えた拡張可能な設計

---

<div align="center">

**🎯 This project demonstrates modern mobile development practices with real-world business value**

*Built with Flutter & ❤️ for families*

</div>