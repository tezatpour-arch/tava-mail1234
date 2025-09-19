import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // حذف دیتابیس (فقط برای توسعه)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    print('Deleting existing database at: $path');
    await deleteDatabase(path);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await deleteDB(); // فقط برای توسعه! در حالت production این خط را بردار
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('Opening database at: $path');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // جدول کاربران
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        nationalId TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');

    // جدول رمزهای SMTP
    await db.execute('''
      CREATE TABLE email_credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        smtpPassword TEXT NOT NULL
      )
    ''');

    // ✅ جدول ایمیل‌های حذف‌شده
    await db.execute('''
      CREATE TABLE deleted_emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // درج کاربران اولیه
    await db.insert('users', {
      'username': 'masadi@tavabojan.ir',
      'password': '',
      'nationalId': '1590729920',
      'phoneNumber': '09120000000', // شماره تلفن رو بگو تا جایگزین کنم
      'email': 'masadi@tavabojan.ir',
      'role': 'مدیرعامل',
    });

    await db.insert('users', {
      'username': 'izivari@tavabojan.ir',
      'password': '',
      'nationalId': '0123456789',
      'phoneNumber': '09120000000',
      'email': 'izivari@tavabojan.ir',
      'role': 'مدیرتدارکات',
    });

    await db.insert('users', {
      'username': 'nnazempor@tavabojan.ir',
      'password': '',
      'nationalId': '1742436692',
      'phoneNumber': '09120000000',
      'email': 'nnazempor@tavabojan.ir',
      'role': 'انباردار',
    });

    await db.insert('users', {
      'username': 'zmohammadzadeh@tavabojan.ir',
      'password': '',
      'nationalId': '0321904311',
      'phoneNumber': '09120000000',
      'email': 'zmohammadzadeh@tavabojan.ir',
      'role': 'مدیر فروش',
    });

    await db.insert('users', {
      'username': 'aabazadeh@tavabojan.ir',
      'password': '',
      'nationalId': '0321898923',
      'phoneNumber': '09120000000',
      'email': 'aabazadeh@tavabojan.ir',
      'role': 'مدیر تولیدی',
    });

    await db.insert('users', {
      'username': 'ealilo@tavabojan.ir',
      'password': '',
      'nationalId': '0123456789',
      'phoneNumber': '09120000000',
      'email': 'ealilo@tavabojan.ir',
      'role': 'مدیرمالی',
    });

    await db.insert('users', {
      'username': 'rdteam@tavabojan.ir',
      'password': '',
      'nationalId': '', // برای تیم تحقیق و توسعه کد ملی ندادید
      'phoneNumber': '09120000000',
      'email': 'rdteam@tavabojan.ir',
      'role': 'تیم تحقیق و توسعه',
    });

    await db.insert('users', {
      'username': 'zfathkhani@tavabojan.ir',
      'password': '',
      'nationalId': '0312063598',
      'phoneNumber': '09120000000',
      'email': 'zfathkhani@tavabojan.ir',
      'role': 'حسابدار',
    });

    await db.insert('users', {
      'username': 'mrezai@tavabojan.ir',
      'password': '',
      'nationalId': '1630351997',
      'phoneNumber': '09120000000',
      'email': 'mrezai@tavabojan.ir',
      'role': 'مسئول تیم آر اند دی',
    });

    await db.insert('users', {
      'username': 'tezatpour@tavabojan.ir',
      'password': '',
      'nationalId': '1520537204', // کد ملی داده نشده
      'phoneNumber': '09120000000',
      'email': 'tezatpour@tavabojan.ir',
      'role': 'مسئول تیم آر اند دی',
    });

    await db.insert('users', {
      'username': 'ashahkarami@tavabojan.ir',
      'password': '',
      'nationalId': '1590384253',
      'phoneNumber': '09120000000',
      'email': 'ashahkarami@tavabojan.ir',
      'role': 'مسئول تیم آر اند دی',
    });

    // درج رمزهای SMTP
    await db.insert('email_credentials', {
      'email': 'tahaezaty1380@gmail.com',
      'smtpPassword': 'ukbx zjql evrg slrj',
    });

    await db.insert('email_credentials', {
      'email': 'rezaeikhangah@gmail.com',
      'smtpPassword': 'your_other_app_password',
    });

    await db.insert('email_credentials', {
      'email': 'shahkrmi666@gmail.com',
      'smtpPassword': 'another_app_password',
    });

    print('All initial data inserted successfully.');
  }

  // دریافت کاربر با نام کاربری
  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // دریافت کاربر با کد ملی
  Future<Map<String, dynamic>?> findUserByNationalId(String nationalId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'nationalId = ?',
      whereArgs: [nationalId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // به‌روزرسانی رمز عبور
  Future<int> updatePassword(String username, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // درج یا بروزرسانی رمز SMTP
  Future<void> upsertEmailCredential(String email, String smtpPassword) async {
    final db = await instance.database;
    final existing = await db.query(
      'email_credentials',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
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

  // دریافت رمز SMTP
  Future<String?> getSmtpPassword(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'email_credentials',
      columns: ['smtpPassword'],
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['smtpPassword'] as String? : null;
  }

  // ✅ درج ایمیل حذف‌شده
  Future<void> insertDeletedEmail(Map<String, dynamic> email) async {
    final db = await instance.database;
    await db.insert('deleted_emails', email);
  }

  // ✅ دریافت لیست ایمیل‌های حذف‌شده
  Future<List<Map<String, dynamic>>> getAllDeletedEmails() async {
    final db = await instance.database;
    return await db.query('deleted_emails', orderBy: 'date DESC');
  }

  Future<void> insertUrgentEmail(Map<String, dynamic> email) async {
    final db = await instance.database;
    await db.insert('urgent_emails', email);

    Future<List<Map<String, dynamic>>> getUrgentEmails() async {
      final db = await instance.database;
      return await db.query(
        'urgent_emails',
        where: 'subject LIKE ?',
        whereArgs: ['%فوری%'],
        orderBy: 'sentDate DESC',
      );
    }
  }
}
