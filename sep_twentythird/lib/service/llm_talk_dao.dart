import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class LlmTalkDao {
  /// 新增一筆對話（一問一答）
  Future<void> insertTalk({
    required String uid,
    required String userInput,
    required String modelOutput,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('llm_talk', {
      'uid': uid,
      'user_input': userInput,
      'model_output': modelOutput,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 讀取某位使用者的所有歷史對話
  Future<List<Map<String, dynamic>>> getTalkHistory(String uid) async {
    final db = await DatabaseHelper.instance.database;

    return await db.query(
      'llm_talk',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'created_at ASC',
    );
  }
}
  