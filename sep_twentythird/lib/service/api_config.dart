import 'dart:io';

class ApiConfig {
  /// 🔥 自動挑選最適 API Host
  static String get baseUrl {
    if (_isAndroidEmulator) {
      // Android 模擬器 → 連 10.0.2.2（host 的 localhost）
      return "http://10.0.2.2:5000";
    }

    if (_isIOSSimulator) {
      // iOS 模擬器 → 用 host 本機
      return "http://localhost:5000";
    }

    // 實體手機 → 換成你電腦在區網內的 IP（自動替換）
    return "http://192.168.0.xxx:5000"; 
  }

  /// 判斷 Android 模擬器
  static bool get _isAndroidEmulator =>
      Platform.isAndroid && !Platform.environment.containsKey('ANDROID_HOME');

  /// 判斷 iOS 模擬器
  static bool get _isIOSSimulator =>
      Platform.isIOS && !Platform.isMacOS;
}
