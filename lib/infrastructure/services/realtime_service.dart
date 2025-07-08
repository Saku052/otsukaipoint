import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import 'supabase_service.dart';

/// リアルタイム通信サービス
/// Supabaseのリアルタイム機能を管理
class RealtimeService {
  static RealtimeService? _instance;
  final SupabaseService _supabaseService;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeService._(this._supabaseService);

  /// シングルトンインスタンスを取得
  static RealtimeService get instance {
    _instance ??= RealtimeService._(SupabaseService.instance);
    return _instance!;
  }

  /// 買い物リストの変更をリッスン
  RealtimeChannel listenToShoppingLists({
    required String familyId,
    required void Function(Map<String, dynamic>) onInsert,
    required void Function(Map<String, dynamic>) onUpdate,
    required void Function(Map<String, dynamic>) onDelete,
  }) {
    final channelName = 'shopping_lists:$familyId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]!.unsubscribe();
    }

    final channel = _supabaseService.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'shopping_lists',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'family_id',
          value: familyId,
        ),
        callback: (payload) {
          try {
            onInsert(payload.newRecord);
          } catch (e) {
            _handleError('shopping_lists insert', e);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'shopping_lists',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'family_id',
          value: familyId,
        ),
        callback: (payload) {
          try {
            onUpdate(payload.newRecord);
          } catch (e) {
            _handleError('shopping_lists update', e);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'shopping_lists',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'family_id',
          value: familyId,
        ),
        callback: (payload) {
          try {
            onDelete(payload.oldRecord);
          } catch (e) {
            _handleError('shopping_lists delete', e);
          }
        },
      )
      .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  /// 買い物商品の変更をリッスン
  RealtimeChannel listenToShoppingItems({
    required String shoppingListId,
    required void Function(Map<String, dynamic>) onInsert,
    required void Function(Map<String, dynamic>) onUpdate,
    required void Function(Map<String, dynamic>) onDelete,
  }) {
    final channelName = 'shopping_items:$shoppingListId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]!.unsubscribe();
    }

    final channel = _supabaseService.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'shopping_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'shopping_list_id',
          value: shoppingListId,
        ),
        callback: (payload) {
          try {
            onInsert(payload.newRecord);
          } catch (e) {
            _handleError('shopping_items insert', e);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'shopping_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'shopping_list_id',
          value: shoppingListId,
        ),
        callback: (payload) {
          try {
            onUpdate(payload.newRecord);
          } catch (e) {
            _handleError('shopping_items update', e);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'shopping_items',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'shopping_list_id',
          value: shoppingListId,
        ),
        callback: (payload) {
          try {
            onDelete(payload.oldRecord);
          } catch (e) {
            _handleError('shopping_items delete', e);
          }
        },
      )
      .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  /// 通知の変更をリッスン
  RealtimeChannel listenToNotifications({
    required String userId,
    required void Function(Map<String, dynamic>) onInsert,
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    final channelName = 'notifications:$userId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]!.unsubscribe();
    }

    final channel = _supabaseService.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          try {
            onInsert(payload.newRecord);
          } catch (e) {
            _handleError('notifications insert', e);
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          try {
            onUpdate(payload.newRecord);
          } catch (e) {
            _handleError('notifications update', e);
          }
        },
      )
      .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  /// お小遣い残高の変更をリッスン
  RealtimeChannel listenToAllowanceBalance({
    required String userId,
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    final channelName = 'allowance_balances:$userId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]!.unsubscribe();
    }

    final channel = _supabaseService.channel(channelName);
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'allowance_balances',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          try {
            onUpdate(payload.newRecord);
          } catch (e) {
            _handleError('allowance_balances update', e);
          }
        },
      )
      .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  /// カスタムイベントを送信
  Future<void> sendCustomEvent({
    required String channelName,
    required String eventName,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final channel = _getOrCreateChannel(channelName);
      await channel.sendBroadcastMessage(
        event: eventName,
        payload: payload,
      );
    } catch (e) {
      throw ServerException(
        message: 'カスタムイベントの送信に失敗しました: $e',
      );
    }
  }

  /// カスタムイベントをリッスン
  RealtimeChannel listenToCustomEvent({
    required String channelName,
    required String eventName,
    required void Function(Map<String, dynamic>) onEvent,
  }) {
    final channel = _getOrCreateChannel(channelName);
    
    channel.onBroadcast(
      event: eventName,
      callback: (payload) {
        try {
          onEvent(payload);
        } catch (e) {
          _handleError('custom event $eventName', e);
        }
      },
    );

    // チャンネルを購読（接続状態の確認は内部で処理される）
    channel.subscribe();

    return channel;
  }

  /// チャンネルを取得または作成
  RealtimeChannel _getOrCreateChannel(String channelName) {
    if (_channels.containsKey(channelName)) {
      return _channels[channelName]!;
    }

    final channel = _supabaseService.channel(channelName);
    _channels[channelName] = channel;
    return channel;
  }

  /// 特定のチャンネルを停止
  void unsubscribeChannel(String channelName) {
    if (_channels.containsKey(channelName)) {
      _channels[channelName]!.unsubscribe();
      _channels.remove(channelName);
    }
  }

  /// すべてのチャンネルを停止
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }

  /// 接続状態を確認
  bool get isConnected {
    try {
      return _supabaseService.client.realtime.isConnected;
    } catch (e) {
      return false;
    }
  }

  /// エラーハンドリング
  void _handleError(String operation, dynamic error) {
    // TODO: ログサービスを実装
    // logger.error('RealtimeService error in $operation: $error');
    // 必要に応じてエラー報告サービスに送信
  }

  /// サービスを破棄
  void dispose() {
    unsubscribeAll();
    _instance = null;
  }
}