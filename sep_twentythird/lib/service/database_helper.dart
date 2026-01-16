import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'ai_skin_scanner.db';

  // ✅ 升版
  static const _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE llm_talk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        user_input TEXT NOT NULL,
        model_output TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 舊表（不動）
    // await _createLegacySeverityTable(db);

    // 新表
    await _createSeverityAssessmentTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // await _createLegacySeverityTable(db);
    }
    if (oldVersion < 3) {
      await _createSeverityAssessmentTable(db);
    }
  }

  // Future<void> _createLegacySeverityTable(Database db) async {
  //   await db.execute('''
  //     CREATE TABLE IF NOT EXISTS severity_record (
  //       id INTEGER PRIMARY KEY AUTOINCREMENT,
  //       uid TEXT NOT NULL,
  //       disease TEXT NOT NULL,
  //       region TEXT NOT NULL,
  //       a INTEGER,
  //       b INTEGER,
  //       c INTEGER,
  //       d INTEGER,
  //       area INTEGER,
  //       total_score REAL NOT NULL,
  //       created_at TEXT NOT NULL
  //     )
  //   ''');
  // }

  /// ✅ 新的一筆一評估表
  Future<void> _createSeverityAssessmentTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS severity_assessment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        disease TEXT NOT NULL,
        total_score REAL NOT NULL,
        created_at TEXT NOT NULL,

        head_area INTEGER NOT NULL,
        head_a INTEGER NOT NULL,
        head_b INTEGER NOT NULL,
        head_c INTEGER NOT NULL,
        head_d INTEGER,

        upper_area INTEGER NOT NULL,
        upper_a INTEGER NOT NULL,
        upper_b INTEGER NOT NULL,
        upper_c INTEGER NOT NULL,
        upper_d INTEGER,

        trunk_area INTEGER NOT NULL,
        trunk_a INTEGER NOT NULL,
        trunk_b INTEGER NOT NULL,
        trunk_c INTEGER NOT NULL,
        trunk_d INTEGER,

        lower_area INTEGER NOT NULL,
        lower_a INTEGER NOT NULL,
        lower_b INTEGER NOT NULL,
        lower_c INTEGER NOT NULL,
        lower_d INTEGER
      )
    ''');
  }
}
