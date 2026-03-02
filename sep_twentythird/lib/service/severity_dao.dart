import 'package:sqflite/sqflite.dart';
import '../service/database_helper.dart';

class SeverityDao {
  Future<Map<String, dynamic>?> getLatestByDisease(
      String uid, String disease) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'severity_assessment',
      where: 'uid = ? AND disease = ?',
      whereArgs: [uid, disease],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }
}