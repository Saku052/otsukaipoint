// ネットワーク情報抽象クラス
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

// ネットワーク情報実装クラス
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // TODO: connectivity_plusパッケージを使用して実装
    // 現在は常にtrueを返す
    return true;
  }
}