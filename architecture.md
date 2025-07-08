# おつかいポイント アーキテクチャ設計

## 1. Clean Architecture 構成

### 1.1 レイヤー構成
```
lib/
├── presentation/        # Presentation Layer (UI)
│   ├── pages/          # 画面
│   ├── widgets/        # 再利用可能なウィジェット
│   └── providers/      # Riverpod プロバイダー
├── domain/             # Domain Layer (ビジネスロジック)
│   ├── entities/       # エンティティ
│   ├── repositories/   # リポジトリインターフェース
│   └── usecases/       # ユースケース
├── infrastructure/     # Infrastructure Layer (外部依存)
│   ├── datasources/    # データソース
│   ├── repositories/   # リポジトリ実装
│   └── services/       # 外部サービス
└── core/              # Core (共通機能)
    ├── constants/      # 定数
    ├── errors/         # エラー定義
    ├── utils/          # ユーティリティ
    └── network/        # ネットワーク設定
```

### 1.2 依存関係
- **Presentation → Domain**: UseCaseを呼び出し
- **Domain → Infrastructure**: Repository interfaceを定義
- **Infrastructure → Domain**: Repository interfaceを実装
- **Core**: 全レイヤーから参照可能

## 2. 状態管理設計 (Riverpod)

### 2.1 プロバイダー構成
```dart
// 認証状態
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>

// 買い物リスト状態  
final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, ShoppingListState>

// お小遣い状態
final allowanceProvider = StateNotifierProvider<AllowanceNotifier, AllowanceState>

// 通知状態
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>
```

### 2.2 状態クラス (Freezed)
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    @Default(false) bool isLoading,
    String? error,
  }) = _AuthState;
}
```

## 3. ドメイン層設計

### 3.1 エンティティ
```dart
// ユーザー
class User {
  final String id;
  final String email;
  final UserRole role;
  final String? name;
}

// 買い物リスト
class ShoppingList {
  final String id;
  final String title;
  final String createdBy;
  final DateTime? deadline;
  final List<ShoppingItem> items;
}

// 商品
class ShoppingItem {
  final String id;
  final String name;
  final double? estimatedPrice;
  final String? suggestedStore;
  final double allowanceAmount;
  final ItemStatus status;
}
```

### 3.2 ユースケース
```dart
// 買い物リスト作成
class CreateShoppingListUseCase {
  Future<Either<Failure, ShoppingList>> call(CreateShoppingListParams params);
}

// 商品完了報告
class CompleteShoppingItemUseCase {
  Future<Either<Failure, void>> call(CompleteShoppingItemParams params);
}

// お小遣い承認
class ApproveAllowanceUseCase {
  Future<Either<Failure, void>> call(ApproveAllowanceParams params);
}
```

## 4. インフラ層設計

### 4.1 Supabase 接続
```dart
class SupabaseClient {
  static final instance = Supabase.instance.client;
  
  // 認証
  static SupabaseAuth get auth => instance.auth;
  
  // データベース
  static SupabaseQueryBuilder from(String table) => instance.from(table);
  
  // リアルタイム
  static RealtimeChannel channel(String name) => instance.channel(name);
}
```

### 4.2 データソース
```dart
abstract class ShoppingListRemoteDataSource {
  Future<List<ShoppingListModel>> getShoppingLists();
  Future<ShoppingListModel> createShoppingList(CreateShoppingListRequest request);
  Future<void> updateShoppingItem(String itemId, ShoppingItemStatus status);
}

class ShoppingListRemoteDataSourceImpl implements ShoppingListRemoteDataSource {
  final SupabaseClient client;
  
  @override
  Future<List<ShoppingListModel>> getShoppingLists() async {
    final response = await client.from('shopping_lists').select('*');
    return response.map((json) => ShoppingListModel.fromJson(json)).toList();
  }
}
```

## 5. リアルタイム通知設計

### 5.1 Supabase Realtime
```dart
class RealtimeService {
  late RealtimeChannel _channel;
  
  void listenToShoppingLists(String userId) {
    _channel = SupabaseClient.channel('shopping_lists:$userId')
      .on(RealtimeListenTypes.postgresChanges, 
          ChangeFilter(event: '*', schema: 'public', table: 'shopping_lists'),
          (payload) => _handleShoppingListChange(payload))
      .subscribe();
  }
  
  void _handleShoppingListChange(Map<String, dynamic> payload) {
    // 通知テーブルにレコード追加
    // 状態更新
  }
}
```

### 5.2 Edge Functions (通知ロジック)
```typescript
// supabase/functions/notify/index.ts
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const { type, userId, data } = await req.json()
  
  // 通知テーブルに挿入
  const { error } = await supabase
    .from('notifications')
    .insert({
      user_id: userId,
      type: type,
      data: data,
      created_at: new Date().toISOString(),
      is_read: false
    })

  return new Response(JSON.stringify({ success: !error }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
})
```

## 6. 型安全性 (Freezed + JSON)

### 6.1 モデル定義
```dart
@freezed
class ShoppingListModel with _$ShoppingListModel {
  const factory ShoppingListModel({
    required String id,
    required String title,
    required String createdBy,
    DateTime? deadline,
    required List<ShoppingItemModel> items,
  }) = _ShoppingListModel;

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) => 
      _$ShoppingListModelFromJson(json);
}
```

### 6.2 API レスポンス
```dart
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse.success(T data) = _Success<T>;
  const factory ApiResponse.error(String message) = _Error<T>;
}
```

## 7. 依存性注入

### 7.1 プロバイダー定義
```dart
// リポジトリ
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepositoryImpl(
    remoteDataSource: ref.read(shoppingListRemoteDataSourceProvider),
  );
});

// ユースケース
final createShoppingListUseCaseProvider = Provider<CreateShoppingListUseCase>((ref) {
  return CreateShoppingListUseCase(
    repository: ref.read(shoppingListRepositoryProvider),
  );
});
```

この設計により、テスタブルで保守しやすいクリーンなアーキテクチャを実現できます。