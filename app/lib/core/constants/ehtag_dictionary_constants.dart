/// EhTagTranslation Database 导入相关常量。
abstract final class EhTagDictionaryConstants {
  static const String latestDbTextJsonUrl =
      'https://github.com/EhTagTranslation/Database/releases/latest/download/db.text.json';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(minutes: 2);
}
