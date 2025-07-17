import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// Supabaseサービス
/// Supabaseの初期化と基本的な操作を提供
class SupabaseService {
  static SupabaseService? _instance;
  late SupabaseClient _client;
  bool _isInitialized = false;

  SupabaseService._();

  /// シングルトンインスタンスを取得
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Supabaseを初期化
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false, // プロダクションではfalse
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      throw ServerException(
        message: 'Supabaseの初期化に失敗しました: $e',
      );
    }
  }

  /// Supabaseクライアントを取得
  SupabaseClient get client {
    if (!isInitialized) {
      throw ServerException(
        message: 'Supabaseが初期化されていません',
      );
    }
    return _client;
  }

  /// 初期化済みかどうかを判定
  bool get isInitialized {
    return _isInitialized;
  }

  /// 認証サービスを取得
  GoTrueClient get auth => client.auth;

  /// データベースクエリを実行
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// ストレージサービスを取得
  SupabaseStorageClient get storage => client.storage;

  /// リアルタイムチャンネルを作成
  RealtimeChannel channel(String name) => client.channel(name);

  /// データベース関数を呼び出し
  Future<PostgrestResponse> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      return await client.rpc(functionName, params: params);
    } catch (e) {
      throw ServerException(
        message: 'データベース関数の実行に失敗しました: $e',
      );
    }
  }

  /// トランザクションを実行
  Future<T> transaction<T>(Future<T> Function() action) async {
    try {
      // Supabaseはトランザクションを直接サポートしていないため、
      // 必要に応じて個別に実装する
      return await action();
    } catch (e) {
      throw ServerException(
        message: 'トランザクションの実行に失敗しました: $e',
      );
    }
  }

  /// エラーハンドリング
  Exception handleError(dynamic error) {
    if (error is PostgrestException) {
      return ServerException(
        message: error.message,
        code: int.tryParse(error.code ?? ''),
      );
    }
    
    if (error.toString().contains('Auth')) {
      return AuthException(
        message: error.toString(),
      );
    }
    
    if (error is StorageException) {
      return ServerException(
        message: error.message,
      );
    }

    return ServerException(
      message: 'サーバーエラーが発生しました: $error',
    );
  }

  /// 接続状態を確認
  Future<bool> checkConnection() async {
    try {
      await client.from('users').select('count').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ヘルスチェック
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await client.rpc('get_health_status');
      return {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'data': response.data,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// サービスを破棄
  void dispose() {
    // Supabaseクライアントのクリーンアップは通常不要
    _instance = null;
  }
}

/// SupabaseServiceプロバイダー
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final service = SupabaseService.instance;
  if (!service.isInitialized) {
    throw StateError('SupabaseServiceが初期化されていません。main()でinitialize()を呼び出してください。');
  }
  return service;
});