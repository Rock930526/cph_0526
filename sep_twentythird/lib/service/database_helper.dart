import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
//開啟資料庫 & 偵測本機有無資料庫存在，若無建立新的資料庫
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'ai_skin_scanner.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // =========================
  // 初始化 DB
  // =========================
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // =========================
  // 建立所有資料表
  // =========================
  Future<void> _onCreate(Database db, int version) async {
    // 🔹 使用者個人資料
    await db.execute('''
      CREATE TABLE user_profile (
        uid TEXT PRIMARY KEY,
        birthday TEXT,
        gender TEXT,
        height_cm REAL,
        weight_kg REAL,
        chronic_conditions TEXT,
        email TEXT,
        phone TEXT,
        updated_at TEXT
      )
    ''');

    // 🔹 LLM 對話紀錄
    await db.execute('''
      CREATE TABLE llm_talk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        user_input TEXT NOT NULL,
        model_output TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 🔹 PASI / 分數紀錄
    await db.execute('''
      CREATE TABLE pasi_score (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        score REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // =========================
  // Debug：列出目前有哪些表
  // =========================
  Future<List<String>> listTables() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    return result.map((e) => e['name'] as String).toList();
  }
}