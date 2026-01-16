import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// =====================================================
/// SeverityRecordDao（最終穩定版）
///
/// 🎯 核心原則（這次請記住）
/// 1️⃣ 只使用 severity_assessment（新表）
/// 2️⃣ 一筆 row = 一次完整評估
/// 3️⃣ 「查詢明細只用 id」，不再用 created_at
/// =====================================================
class SeverityRecordDao {

  /// =====================================================
  /// 新增一筆完整評估
  ///
  /// 🔹 UI 呼叫方式不變
  /// 🔹 regions 結構不變
  /// 🔹 乾癬 d 欄位存 null，濕疹才有值
  /// =====================================================
  Future<void> insertRecords({
    required String uid,
    required String disease, // psoriasis / eczema
    required double totalScore,
    required Map<String, Map<String, int>> regions,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // 統一格式（顯示用，不再當 key）
    final now = DateTime.now().toString().substring(0, 19);

    final head  = regions['頭']!;
    final upper = regions['上肢']!;
    final trunk = regions['軀幹']!;
    final lower = regions['下肢']!;

    await db.insert(
      'severity_assessment',
      {
        'uid': uid,
        'disease': disease,
        'total_score': totalScore,
        'created_at': now,

        // ===== 頭 =====
        'head_area': head['area'],
        'head_a': head['a'],
        'head_b': head['b'],
        'head_c': head['c'],
        'head_d': disease == 'eczema' ? head['d'] : null,

        // ===== 上肢 =====
        'upper_area': upper['area'],
        'upper_a': upper['a'],
        'upper_b': upper['b'],
        'upper_c': upper['c'],
        'upper_d': disease == 'eczema' ? upper['d'] : null,

        // ===== 軀幹 =====
        'trunk_area': trunk['area'],
        'trunk_a': trunk['a'],
        'trunk_b': trunk['b'],
        'trunk_c': trunk['c'],
        'trunk_d': disease == 'eczema' ? trunk['d'] : null,

        // ===== 下肢 =====
        'lower_area': lower['area'],
        'lower_a': lower['a'],
        'lower_b': lower['b'],
        'lower_c': lower['c'],
        'lower_d': disease == 'eczema' ? lower['d'] : null,
      },
    );
  }

  /// =====================================================
  /// 抓最近 N 次評估（給趨勢圖）
  ///
  /// ⚠️ 關鍵：
  /// - 一定要回傳 id
  /// - UI 點擊時只用 id 查
  /// =====================================================
  Future<List<Map<String, dynamic>>> getRecentScores({
    required String uid,
    required String disease,
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'severity_assessment',
      columns: ['id', 'created_at', 'total_score'],
      where: 'uid = ? AND disease = ?',
      whereArgs: [uid, disease],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    // UI 習慣舊 → 新
    return rows.reversed.toList();
  }

  /// =====================================================
  /// ✅ 最重要的方法
  /// 用「assessment id」抓四部位明細
  ///
  /// ❌ 不再用 created_at
  /// ❌ 不可能再抓不到
  /// =====================================================
  Future<List<Map<String, dynamic>>> getRecordsById({
    required int id,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'severity_assessment',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return [];

    final r = rows.first;

    // 拆回 UI 需要的四筆格式
    return [
      {
        'region': '頭',
        'area': r['head_area'],
        'a': r['head_a'],
        'b': r['head_b'],
        'c': r['head_c'],
        'd': r['head_d'],
      },
      {
        'region': '上肢',
        'area': r['upper_area'],
        'a': r['upper_a'],
        'b': r['upper_b'],
        'c': r['upper_c'],
        'd': r['upper_d'],
      },
      {
        'region': '軀幹',
        'area': r['trunk_area'],
        'a': r['trunk_a'],
        'b': r['trunk_b'],
        'c': r['trunk_c'],
        'd': r['trunk_d'],
      },
      {
        'region': '下肢',
        'area': r['lower_area'],
        'a': r['lower_a'],
        'b': r['lower_b'],
        'c': r['lower_c'],
        'd': r['lower_d'],
      },
    ];
  }
}
