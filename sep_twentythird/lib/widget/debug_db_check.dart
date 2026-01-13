import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DebugDbCheck {
  static const String dbName = 'ai_skin_scanner.db';

  /// Debug 用：
  /// - 每次啟動都可呼叫
  /// - 不修改任何 schema
  /// - 只負責「驗證目前 DB 真實狀態」
  static Future<void> checkAndCreateDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, dbName);

    debugPrint('──────── DB DEBUG START ────────');
    debugPrint('📂 Databases path: $dbPath');
    debugPrint('📄 Full DB path: $fullPath');

    final existsBefore = await databaseExists(fullPath);
    debugPrint('❓ DB exists: $existsBefore');

    if (!existsBefore) {
      debugPrint('⚠️ DB file does NOT exist yet');
      debugPrint('──────── DB DEBUG END ────────');
      return;
    }

    final db = await openDatabase(fullPath);

    // 列出所有 table
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );

    debugPrint('📋 Tables in DB (${tables.length}):');
    for (final row in tables) {
      debugPrint('  • ${row['name']}');
    }

    // 檢查 user_profile 是否存在（你目前最在意的）
    final userProfileExists = tables.any(
      (t) => t['name'] == 'user_profile',
    );
    debugPrint(
      userProfileExists
          ? '✅ user_profile table exists'
          : '❌ user_profile table MISSING',
    );

    await db.close();
    debugPrint('──────── DB DEBUG END ────────');
  }
}
