// バリデーションユーティリティ
class Validators {
  // メールアドレス検証
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }
  
  // パスワード検証（8文字以上）
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }
  
  // 名前検証（空でないかつ50文字以内）
  static bool isValidName(String name) {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty && trimmedName.length <= 50;
  }
  
  // 商品名検証（空でないかつ100文字以内）
  static bool isValidItemName(String name) {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty && trimmedName.length <= 100;
  }
  
  // 価格検証（0以上）
  static bool isValidPrice(double price) {
    return price >= 0;
  }
  
  // お小遣い金額検証（0以上）
  static bool isValidAllowanceAmount(double amount) {
    return amount >= 0;
  }
  
  // 買い物リストタイトル検証（空でないかつ100文字以内）
  static bool isValidShoppingListTitle(String title) {
    final trimmedTitle = title.trim();
    return trimmedTitle.isNotEmpty && trimmedTitle.length <= 100;
  }
  
  // 説明文検証（1000文字以内）
  static bool isValidDescription(String description) {
    return description.length <= 1000;
  }
  
  // 店舗名検証（100文字以内）
  static bool isValidStoreName(String storeName) {
    return storeName.length <= 100;
  }
  
  // 文字数制限チェック
  static bool isWithinCharacterLimit(String text, int limit) {
    return text.length <= limit;
  }
  
  // 空文字チェック
  static bool isNotEmpty(String text) {
    return text.trim().isNotEmpty;
  }
  
  // 数値範囲チェック
  static bool isWithinRange(double value, double min, double max) {
    return value >= min && value <= max;
  }
  
  // 日付が未来かチェック
  static bool isFutureDate(DateTime date) {
    return date.isAfter(DateTime.now());
  }
  
  // 日付が過去かチェック
  static bool isPastDate(DateTime date) {
    return date.isBefore(DateTime.now());
  }
  
  // プライベートコンストラクタ
  Validators._();
}