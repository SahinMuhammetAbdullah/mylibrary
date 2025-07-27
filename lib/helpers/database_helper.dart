// lib/helpers/database_helper.dart
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
    return await openDatabase(path, version: 1, onCreate: _onCreate, onConfigure: _onConfigure);
  }
  
  // onConfigure, veritabanı açıldığında her seferinde çalışır.
  // Foreign Key desteğini garanti altına almak için en iyi yerdir.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

Future<void> _onCreate(Database db, int version) async {
    debugPrint("--- SAYFA SAYISI EKlenmiş VERİTABANI ŞEMASI OLUŞTURULUYOR (_onCreate) ---");
    final batch = db.batch();

    await db.execute("PRAGMA foreign_keys = ON");

    // === BOOKS TABLOSU GÜNCELLENDİ ===
    batch.execute('CREATE TABLE Books(b_id INTEGER PRIMARY KEY, b_name TEXT, b_oWorkId TEXT UNIQUE, b_description TEXT, b_coverUrl TEXT, b_totalPages INTEGER)');
    
    // Diğer tablolar aynı kalır
    batch.execute('CREATE TABLE User(u_id INTEGER PRIMARY KEY, u_userName TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Author(a_id INTEGER PRIMARY KEY, a_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Publisher(pbl_id INTEGER PRIMARY KEY, pbl_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Subject(sbj_id INTEGER PRIMARY KEY, sbj_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Person(prs_id INTEGER PRIMARY KEY, prs_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Place(plc_id INTEGER PRIMARY KEY, plc_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Time(t_id INTEGER PRIMARY KEY, t_name TEXT NOT NULL UNIQUE)');
    batch.execute('CREATE TABLE Notes(n_id INTEGER PRIMARY KEY, u_id INTEGER NOT NULL, b_id INTEGER NOT NULL, n_text TEXT NOT NULL, n_createdAt TEXT NOT NULL, FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (u_id) REFERENCES User(u_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Library(l_id INTEGER PRIMARY KEY, u_id INTEGER NOT NULL, b_id INTEGER NOT NULL, b_addLibAt TEXT NOT NULL, FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (u_id) REFERENCES User(u_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Book_Author(b_id INTEGER NOT NULL, a_id INTEGER NOT NULL, PRIMARY KEY (b_id, a_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (a_id) REFERENCES Author(a_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Book_Publisher(b_id INTEGER NOT NULL, pbl_id INTEGER NOT NULL, PRIMARY KEY (b_id, pbl_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (pbl_id) REFERENCES Publisher(pbl_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Book_Subject(b_id INTEGER NOT NULL, sbj_id INTEGER NOT NULL, PRIMARY KEY (b_id, sbj_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (sbj_id) REFERENCES Subject(sbj_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Book_Person(b_id INTEGER NOT NULL, prs_id INTEGER NOT NULL, PRIMARY KEY (b_id, prs_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (prs_id) REFERENCES Person(prs_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Book_Place(b_id INTEGER NOT NULL, plc_id INTEGER NOT NULL, PRIMARY KEY (b_id, plc_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (plc_id) REFERENCES Place(plc_id) ON DELETE CASCADE)');
    batch.execute('CREATE TABLE Book_Time(b_id INTEGER NOT NULL, t_id INTEGER NOT NULL, PRIMARY KEY (b_id, t_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (t_id) REFERENCES Time(t_id) ON DELETE CASCADE)');

    batch.insert('User', {'u_userName': 'defaultUser'});
    await batch.commit(noResult: true);
  }
}
