import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'book_app_v1.db');
    debugPrint("--- Veritabanı Yolu: $path ---");
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint("--- YENİ VERİTABANI ŞEMASI OLUŞTURULUYOR (_onCreate) ---");
    final batch = db.batch();

    // Books Feature Tables
    batch.execute('''
      CREATE TABLE Books(
        b_id INTEGER PRIMARY KEY AUTOINCREMENT,
        b_name TEXT, b_totalPage TEXT, b_coverUrl TEXT, b_publishDate TEXT,
        b_description TEXT, b_lang TEXT, b_isbn10 TEXT, b_isbn13 TEXT,
        b_isbnOL TEXT, b_rating TEXT, b_oWorkId TEXT UNIQUE
      )
    ''');
    batch.execute('CREATE TABLE Author(a_id INTEGER PRIMARY KEY AUTOINCREMENT, a_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Publisher(pbl_id INTEGER PRIMARY KEY AUTOINCREMENT, pbl_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Subject(sbj_id INTEGER PRIMARY KEY AUTOINCREMENT, sbj_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Person(prs_id INTEGER PRIMARY KEY AUTOINCREMENT, prs_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Place(plc_id INTEGER PRIMARY KEY AUTOINCREMENT, plc_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Time(t_id INTEGER PRIMARY KEY AUTOINCREMENT, t_name TEXT NOT NULL UNIQUE)');

    // Junction Tables for Books
    batch.execute('CREATE TABLE Book_Author(b_id INTEGER NOT NULL, a_id INTEGER NOT NULL, PRIMARY KEY (b_id, a_id))');
    batch.execute('CREATE TABLE Book_Publisher(b_id INTEGER NOT NULL, pbl_id INTEGER NOT NULL, PRIMARY KEY (b_id, pbl_id))');
    batch.execute('CREATE TABLE Book_Subject(b_id INTEGER NOT NULL, sbj_id INTEGER NOT NULL, PRIMARY KEY (b_id, sbj_id))');

    // User Feature Tables
    batch.execute('''
      CREATE TABLE User(
        u_id INTEGER PRIMARY KEY AUTOINCREMENT,
        u_userName TEXT NOT NULL UNIQUE, u_name TEXT, u_email TEXT UNIQUE,
        u_password TEXT, u_age TEXT, u_publicId INTEGER
      )
    ''');
    batch.execute('''
      CREATE TABLE Library(
        l_id INTEGER PRIMARY KEY AUTOINCREMENT,
        u_id INTEGER NOT NULL, b_id INTEGER NOT NULL, b_addLibAt TEXT NOT NULL
      )
    ''');

    // App Feature Tables
    batch.execute('''
      CREATE TABLE Notes(
        n_id INTEGER PRIMARY KEY AUTOINCREMENT,
        u_id INTEGER NOT NULL, b_id INTEGER NOT NULL, n_text TEXT NOT NULL
      )
    ''');

    // Insert a default user for the app to work with
    batch.insert('User', {'u_userName': 'defaultUser', 'u_name': 'Kullanıcı'});

    await batch.commit(noResult: true);
    debugPrint("--- TÜM TABLOLAR BAŞARIYLA OLUŞTURULDU ---");
  }
}
