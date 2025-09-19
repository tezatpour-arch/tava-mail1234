import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppearanceSettingsDB {
  static final AppearanceSettingsDB instance = AppearanceSettingsDB._init();

  static Database? _database;

  AppearanceSettingsDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'appearance_settings.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            isDarkTheme INTEGER,
            fontSize TEXT
          )
        ''');
        await db.insert('settings', {
          'id': 1,
          'isDarkTheme': 0,
          'fontSize': 'متوسط',
        });
      },
    );
  }
}
