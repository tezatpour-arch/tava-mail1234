// services/WeeklyReportDB.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class WeeklyReportDB {
  static final WeeklyReportDB instance = WeeklyReportDB._init();
  static Database? _database;

  WeeklyReportDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('weekly_report.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // جدول اصلی گزارش‌ها
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weekly_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderEmail TEXT NOT NULL,
        receiverEmail TEXT NOT NULL,
        subject TEXT NOT NULL,
        body TEXT NOT NULL,
        filePath TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // جدول ایمیل‌ها (اختیاری)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS email_credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        smtpPassword TEXT NOT NULL
      )
    ''');
  }

  // ---------------------- CRUD گزارش‌ها ----------------------

  Future<int> insertReport(Map<String, dynamic> report) async {
    final db = await instance.database;
    return await db.insert('weekly_reports', report);
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final db = await instance.database;
    return await db.query('weekly_reports', orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>?> getReportById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'weekly_reports',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // حذف گزارش بدون سطل زباله
  Future<void> deleteReport(int reportId) async {
    final db = await instance.database;
    await db.delete('weekly_reports', where: 'id = ?', whereArgs: [reportId]);
  }

  // ---------------------- ایمیل‌ها ----------------------

  Future<String?> getSmtpPassword(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'email_credentials',
      columns: ['smtpPassword'],
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first['smtpPassword'] as String?;
    return null;
  }

  Future<void> upsertEmailCredential(String email, String smtpPassword) async {
    final db = await instance.database;
    final existing = await db.query(
      'email_credentials',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (existing.isEmpty) {
      await db.insert('email_credentials', {
        'email': email,
        'smtpPassword': smtpPassword,
      });
    } else {
      await db.update(
        'email_credentials',
        {'smtpPassword': smtpPassword},
        where: 'email = ?',
        whereArgs: [email],
      );
    }
  }
}
