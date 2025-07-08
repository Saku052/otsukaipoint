import 'package:flutter/material.dart';

/// アプリ内ログ表示用のシングルトンクラス
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static AppLogger get instance => _instance;

  final List<LogEntry> _logs = [];
  final int maxLogs = 100;

  /// ログを追加
  void log(String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    );
    
    _logs.add(entry);
    
    // 最大ログ数を超えた場合は古いものを削除
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
    
    // コンソールにも出力
    print('${entry.timestamp.toIso8601String()} [${level.name.toUpperCase()}] $message');
  }

  /// すべてのログを取得
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// ログをクリア
  void clear() {
    _logs.clear();
  }

  /// 特定レベル以上のログを取得
  List<LogEntry> getLogsOfLevel(LogLevel minLevel) {
    return _logs.where((log) => log.level.index >= minLevel.index).toList();
  }
}

/// ログエントリ
class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${level.name.toUpperCase()}] $message';
  }
}

/// ログレベル
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

extension LogLevelExtension on LogLevel {
  Color get color {
    switch (this) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }
}