// 基底例外クラス
class AppException implements Exception {
  final String message;
  final int? code;
  
  const AppException({required this.message, this.code});
  
  @override
  String toString() => 'AppException: $message (code: $code)';
}

// サーバー例外
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
  });
}

// ネットワーク例外
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
  });
}

// 認証例外
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
  });
}

// 権限例外
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
  });
}

// 検証例外
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
  });
}

// キャッシュ例外
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
  });
}

// データ形式例外
class DataFormatException extends AppException {
  const DataFormatException({
    required super.message,
    super.code,
  });
}