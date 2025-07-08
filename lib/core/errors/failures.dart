import 'package:equatable/equatable.dart';

// 基底失敗クラス
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  
  const Failure({required this.message, this.code});
  
  @override
  List<Object?> get props => [message, code];
}

// サーバー失敗
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

// ネットワーク失敗
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

// 認証失敗
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

// 権限失敗
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
  });
}

// 検証失敗
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

// キャッシュ失敗
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

// データ形式失敗
class DataFormatFailure extends Failure {
  const DataFormatFailure({
    required super.message,
    super.code,
  });
}

// 不明な失敗
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
  });
}