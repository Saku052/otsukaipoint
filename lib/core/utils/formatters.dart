import 'package:intl/intl.dart';

// フォーマッターユーティリティ
class Formatters {
  // 通貨フォーマット
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'ja_JP');
    return '¥${formatter.format(amount)}';
  }
  
  // 日付フォーマット（年月日）
  static String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy年MM月dd日', 'ja_JP');
    return formatter.format(date);
  }
  
  // 日付フォーマット（月日）
  static String formatShortDate(DateTime date) {
    final formatter = DateFormat('MM月dd日', 'ja_JP');
    return formatter.format(date);
  }
  
  // 時刻フォーマット
  static String formatTime(DateTime time) {
    final formatter = DateFormat('HH:mm', 'ja_JP');
    return formatter.format(time);
  }
  
  // 日付時刻フォーマット
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy年MM月dd日 HH:mm', 'ja_JP');
    return formatter.format(dateTime);
  }
  
  // 相対時間フォーマット
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
  
  // 残り時間フォーマット
  static String formatRemainingTime(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return '期限切れ';
    } else if (difference.inDays > 0) {
      return '残り${difference.inDays}日';
    } else if (difference.inHours > 0) {
      return '残り${difference.inHours}時間';
    } else if (difference.inMinutes > 0) {
      return '残り${difference.inMinutes}分';
    } else {
      return '残り1分未満';
    }
  }
  
  // 進捗率フォーマット
  static String formatProgressPercentage(int completed, int total) {
    if (total == 0) return '0%';
    final percentage = (completed / total * 100).round();
    return '$percentage%';
  }
  
  // 商品数フォーマット
  static String formatItemCount(int count) {
    return '$count個';
  }
  
  // 文字数制限表示
  static String formatCharacterCount(int current, int max) {
    return '$current/$max文字';
  }
  
  // 電話番号フォーマット
  static String formatPhoneNumber(String phoneNumber) {
    // 日本の電話番号形式に変換
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phoneNumber;
  }
  
  // ファイルサイズフォーマット
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  // プライベートコンストラクタ
  Formatters._();
}