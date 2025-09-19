// lib/services/db_service.dart

import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// ======================= MODELS =======================

class EmailReceived {
  int? id;
  String senderEmail;
  String subject;
  String body;
  DateTime receivedDate;
  bool isRead;

  EmailReceived({
    this.id,
    required this.senderEmail,
    required this.subject,
    required this.body,
    required this.receivedDate,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'senderEmail': senderEmail,
    'subject': subject,
    'body': body,
    'receivedDate': receivedDate.toIso8601String(),
    'isRead': isRead ? 1 : 0,
  };

  factory EmailReceived.fromMap(Map<String, dynamic> map) => EmailReceived(
    id: map['id'] as int?,
    senderEmail: map['senderEmail'] as String,
    subject: map['subject'] as String,
    body: map['body'] as String,
    receivedDate: DateTime.parse(map['receivedDate'] as String),
    isRead: (map['isRead'] as int) == 1,
  );
}

class SentEmail {
  final int? id;
  final String subject;
  final String recipient;
  final String body;
  final String sender;
  final DateTime sentDate;
  final List<String> attachments;

  SentEmail({
    this.id,
    required this.subject,
    required this.recipient,
    required this.body,
    required this.sender,
    required this.sentDate,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject': subject,
      'recipient': recipient,
      'body': body,
      'sender': sender,
      'sentDate': sentDate.toIso8601String(),
      'attachments': attachments.join(','), // لیست به رشته تبدیل شد
    };
  }

  factory SentEmail.fromMap(Map<String, dynamic> map) {
    return SentEmail(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      recipient: map['recipient'] as String,
      body: map['body'] as String,
      sender: map['sender'] as String,
      sentDate: DateTime.parse(map['sentDate'] as String),
      attachments: (map['attachments'] as String?)?.isNotEmpty == true
          ? (map['attachments'] as String).split(',')
          : [],
    );
  }
}

class Invoice {
  int? id;
  String description;
  String filePath;
  DateTime date;
  String status;
  String receiver;

  Invoice({
    this.id,
    required this.description,
    required this.filePath,
    required this.date,
    this.status = 'در حال بررسی',
    required this.receiver,
    required String sender,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'description': description,
    'filePath': filePath,
    'date': date.toIso8601String(),
    'status': status,
    'receiver': receiver,
  };

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
    id: map['id'] as int?,
    description: map['description'] as String,
    filePath: map['filePath'] as String,
    date: DateTime.parse(map['date'] as String),
    status: map['status'] as String,
    receiver: map['receiver'] as String,
    sender: '',
  );

  String? get sender => null;
}

/// ======================= DB SERVICE =======================

class DBService {
  // Singleton
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;
  static const _dbName = 'emails.db';
  static const _dbVersion = 6;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // create tables (use IF NOT EXISTS to be safe)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS received_emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderEmail TEXT NOT NULL,
        subject TEXT NOT NULL,
        body TEXT NOT NULL,
        receivedDate TEXT NOT NULL,
        isRead INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sent_emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL,
        recipient TEXT NOT NULL,
        subject TEXT NOT NULL,
        body TEXT NOT NULL,
        sentDate TEXT NOT NULL,
        attachments TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        filePath TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        receiver TEXT NOT NULL
      )
    ''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS sent_emails (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender TEXT NOT NULL,
    recipient TEXT NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    sentDate TEXT NOT NULL,
    attachments TEXT DEFAULT ''
  )
''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_emails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        sender TEXT NOT NULL,
        body TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT NOT NULL,
        subject TEXT NOT NULL,
        receiverRole TEXT NOT NULL,
        receiverEmail TEXT NOT NULL,
        body TEXT NOT NULL,
        attachments TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        noteType TEXT NOT NULL,
        sender TEXT NOT NULL,
        subject TEXT NOT NULL,
        severity TEXT,
        text TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureAttachmentsColumn(Database db) async {
    // بررسی وجود ستون attachments
    final result = await db.rawQuery("PRAGMA table_info(sent_emails)");
    final columnExists = result.any(
      (column) => column['name'] == 'attachments',
    );
    if (!columnExists) {
      await db.execute(
        "ALTER TABLE sent_emails ADD COLUMN attachments TEXT DEFAULT ''",
      );
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // safe upgrades: create missing tables when upgrading from older versions
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invoices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          filePath TEXT NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          receiver TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_emails (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          sender TEXT NOT NULL,
          body TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          noteType TEXT NOT NULL,
          sender TEXT NOT NULL,
          subject TEXT NOT NULL,
          severity TEXT,
          text TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // add attachments column to drafts/sent_emails if not present
      try {
        await db.execute(
          "ALTER TABLE drafts ADD COLUMN attachments TEXT DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE sent_emails ADD COLUMN attachments TEXT DEFAULT ''",
        );
      } catch (_) {}
    }
  }

  // ---------------------- DRAFTS ----------------------

  // ------------------- RECEIVED EMAILS -------------------

  Future<int> insertReceivedEmail(EmailReceived email) async {
    final db = await database;
    return await db.insert('received_emails', email.toMap());
  }

  Future<List<EmailReceived>> getAllReceivedEmails() async {
    final db = await database;
    final result = await db.query(
      'received_emails',
      orderBy: 'receivedDate DESC',
    );
    return result.map((e) => EmailReceived.fromMap(e)).toList();
  }

  Future<void> markEmailAsRead(int id) async {
    final db = await database;
    await db.update(
      'received_emails',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(
      directory.path,
      'db_service.db',
    ); // اسم دیتابیس خودت رو بذار
    if (await File(path).exists()) {
      await deleteDatabase(path);
    }
  }

  // ------------------- SENT EMAILS -------------------
  Future<int> insertSentEmail(SentEmail email) async {
    final db = await database;

    // بررسی وجود ستون attachments
    final tableInfo = await db.rawQuery("PRAGMA table_info(sent_emails)");
    final hasAttachments = tableInfo.any((col) => col['name'] == 'attachments');

    final data = {
      'subject': email.subject,
      'recipient': email.recipient,
      'body': email.body,
      'sender': email.sender,
      'sentDate': email.sentDate.toIso8601String(),
      if (hasAttachments) 'attachments': email.attachments.join(','),
    };

    return await db.insert('sent_emails', data);
  }

  Future<List<SentEmail>> getAllSentEmails() async {
    final db = await database;
    final result = await db.query('sent_emails', orderBy: 'sentDate DESC');
    return result.map((e) => SentEmail.fromMap(e)).toList();
  }

  Future<int> deleteSentEmail(int id) async {
    final db = await database;
    return await db.delete('sent_emails', where: 'id = ?', whereArgs: [id]);
  }

  /// انتقال ایمیل به deleted_emails (سطل زباله) و سپس حذف از sent_emails
  Future<void> trashEmail(int id) async {
    final db = await database;

    final List<Map<String, dynamic>> emails = await db.query(
      'sent_emails',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (emails.isEmpty) return;

    final email = emails.first;

    await db.insert('deleted_emails', {
      'subject': email['subject'],
      'sender': email['sender'],
      'body': email['body'],
      'date': DateTime.now().toIso8601String(),
    });

    await db.delete('sent_emails', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertDeletedEmail({
    required String subject,
    required String sender,
    required String body,
    required String date,
  }) async {
    final db = await database;
    return await db.insert('deleted_emails', {
      'subject': subject,
      'sender': sender,
      'body': body,
      'date': date,
    });
  }

  // ------------------- DELETED EMAILS (TRASH) -------------------

  Future<List<Map<String, dynamic>>> getAllDeletedEmails() async {
    final db = await database;
    return await db.query('deleted_emails', orderBy: 'date DESC');
  }

  Future<int> deleteDeletedEmail(int id) async {
    final db = await database;
    return await db.delete('deleted_emails', where: 'id = ?', whereArgs: [id]);
  }

  /// بازگردانی از deleted_emails به sent_emails
  Future<void> restoreDeletedEmail(
    int id, {
    String defaultRecipient = '',
  }) async {
    final db = await database;
    final result = await db.query(
      'deleted_emails',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return;

    final data = result.first;
    // بازسازی SentEmail از رکورد deleted_emails
    final restored = SentEmail(
      sender: data['sender'] as String,
      recipient: defaultRecipient.isNotEmpty
          ? defaultRecipient
          : (data['sender'] as String),
      subject: data['subject'] as String,
      body: data['body'] as String,
      sentDate: DateTime.tryParse(data['date'] as String) ?? DateTime.now(),
      attachments: [],
    );

    await insertSentEmail(restored);
    await deleteDeletedEmail(id);
  }

  // ------------------- INVOICES -------------------

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final result = await db.query('invoices', orderBy: 'date DESC');
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- UTIL -------------------

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
