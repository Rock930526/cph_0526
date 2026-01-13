import 'package:sqflite/sqflite.dart';
import '../service/database_helper.dart';
import '../service/user_profile.dart';

class UserProfileDao {
  Future<void> upsertProfile({
    required String uid,
    DateTime? birthday,
    String? gender,
    double? heightCm,
    double? weightKg,
    Set<String>? chronicConditions,
    String? email,
    String? phone,
  }) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'user_profile',
      {
        'uid': uid,
        'birthday': birthday?.toIso8601String(),
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'chronic_conditions': chronicConditions?.join(','),
        'email': email,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

    Future<UserProfile?> getProfileByUid(String uid) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'user_profile',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return UserProfile.fromMap(result.first);
  }

}