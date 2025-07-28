// lib/helpers/database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Bu sınıf, uygulamanın tüm veritabanı işlemlerini yönetir.
/// Singleton deseni kullanılarak, uygulama boyunca sadece tek bir örneğinin olması sağlanır.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  DatabaseHelper._privateConstructor();

  /// Veritabanı örneğine erişim noktası.
  /// Eğer veritabanı daha önce açılmadıysa, onu başlatır.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Veritabanını cihazda fiziksel olarak oluşturur veya mevcut olanı açar.
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'book_app_v1.db');
    debugPrint("--- Veritabanı Yolu: $path ---");
    return await openDatabase(
      path,
      version:
          1, // Veritabanı versiyonu. Gelecekteki şema değişiklikleri için artırılabilir.
      onCreate:
          _onCreate, // Veritabanı ilk kez oluşturulduğunda çalışacak metot.
      onConfigure:
          _onConfigure, // Veritabanı her açıldığında konfigürasyon için çalışır.
    );
  }

  /// Veritabanı her açıldığında çalışır.
  /// FOREIGN KEY (Yabancı Anahtar) desteğini etkinleştirmek için en güvenilir yerdir.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Bu metot, veritabanı dosyası cihazda bulunmadığında SADECE BİR KEZ çalışır.
  /// Uygulamanın ihtiyaç duyduğu tüm tablolar burada oluşturulur.
  Future<void> _onCreate(Database db, int version) async {
    debugPrint("--- ANALYTICS VERİTABANI ŞEMASI OLUŞTURULUYOR (_onCreate) ---");
    // Batch, birden çok SQL komutunu tek bir atomik işlemde çalıştırmayı sağlar.
    // Bu, performansı artırır ve işlemlerden biri başarısız olursa hepsinin geri alınmasını sağlar.
    final batch = db.batch();

    // --- ANA VARLIK TABLOLARI ---
    // Bu tablolar, temel ve genellikle değişmeyen verileri tutar.

    // Stores the core, static information about each book fetched from the API.
    batch.execute('''
      CREATE TABLE Books(
        b_id INTEGER PRIMARY KEY,                      -- Kitabın benzersiz kimliği (Otomatik artar)
        b_name TEXT,                                   -- Kitabın adı
        b_oWorkId TEXT UNIQUE,                         -- Open Library'deki benzersiz Work ID'si. Tekrarlı kitap eklenmesini önler.
        b_description TEXT,                            -- Kitabın açıklaması
        b_coverUrl TEXT,                               -- Kitabın kapak resminin URL'si
        b_totalPages INTEGER,                          -- Kitabın toplam sayfa sayısı
        b_publishDate TEXT                             -- Kitabın yayınlanma tarihi (metin olarak)
      )
    ''');

    // Stores user information. Currently, only a default user is created.
    batch.execute('''
      CREATE TABLE User(
        u_id INTEGER PRIMARY KEY,                      -- Kullanıcının benzersiz kimliği
        u_userName TEXT NOT NULL UNIQUE                -- Kullanıcının benzersiz adı
      )
    ''');

    // Stores unique author names to avoid repetition in the database.
    batch.execute(
        'CREATE TABLE Author(a_id INTEGER PRIMARY KEY, a_name TEXT NOT NULL UNIQUE)');
    // Stores unique publisher names.
    batch.execute(
        'CREATE TABLE Publisher(pbl_id INTEGER PRIMARY KEY, pbl_name TEXT NOT NULL UNIQUE)');
    // Stores unique subject/genre names.
    batch.execute(
        'CREATE TABLE Subject(sbj_id INTEGER PRIMARY KEY, sbj_name TEXT NOT NULL UNIQUE)');
    // Stores unique person names mentioned in the book.
    batch.execute(
        'CREATE TABLE Person(prs_id INTEGER PRIMARY KEY, prs_name TEXT NOT NULL UNIQUE)');
    // Stores unique place names mentioned in the book.
    batch.execute(
        'CREATE TABLE Place(plc_id INTEGER PRIMARY KEY, plc_name TEXT NOT NULL UNIQUE)');
    // Stores unique time periods mentioned in the book.
    batch.execute(
        'CREATE TABLE Time(t_id INTEGER PRIMARY KEY, t_name TEXT NOT NULL UNIQUE)');

    // --- KULLANICI ETKİLEŞİM TABLOLARI ---
    // Bu tablolar, kullanıcıların diğer varlıklarla nasıl etkileşime girdiğini kaydeder.

    // This is the core table for tracking user's interaction with a book. It replaces the old 'Library' table.
    batch.execute('''
      CREATE TABLE Analytics(
        a_id INTEGER PRIMARY KEY,                      -- Bu etkileşimin benzersiz kimliği
        u_id INTEGER NOT NULL,                         -- Etkileşimi yapan kullanıcı (User tablosuna referans)
        b_id INTEGER NOT NULL,                         -- Etkileşime girilen kitap (Books tablosuna referans)
        a_status TEXT NOT NULL,                        -- Kitabın durumu ('wishlist', 'reading', 'completed')
        a_rating INTEGER,                              -- Kullanıcının kitaba verdiği puan (1-5)
        a_currentPage INTEGER DEFAULT 0,               -- Kullanıcının kitapta kaldığı sayfa
        a_startedAt TEXT,                              -- Okumaya başlama tarihi (ISO 8601 formatında metin)
        a_finishedAt TEXT,                             -- Okumayı bitirme tarihi
        a_lastReadAt TEXT,                             -- Kitabın en son okunduğu tarih
        UNIQUE(u_id, b_id),                            -- Bir kullanıcının aynı kitabı birden fazla kez eklemesini önler
        FOREIGN KEY (u_id) REFERENCES User(u_id) ON DELETE CASCADE, -- Eğer bir kullanıcı silinirse, tüm analitik verileri de silinir.
        FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE  -- Eğer bir kitap silinirse, bu kitaba ait tüm analitik verileri de silinir.
      )
    ''');

    // Stores user-specific notes for each book.
    batch.execute('''
      CREATE TABLE Notes(
        n_id INTEGER PRIMARY KEY,
        u_id INTEGER NOT NULL,
        b_id INTEGER NOT NULL,
        n_text TEXT NOT NULL,
        n_createdAt TEXT NOT NULL,                     -- Notun oluşturulma tarihi
        FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, -- Eğer bir kitap silinirse, notları da otomatik olarak silinir.
        FOREIGN KEY (u_id) REFERENCES User(u_id) ON DELETE CASCADE   -- Eğer bir kullanıcı silinirse, notları da silinir.
      )
    ''');

    // --- İLİŞKİ (JUNCTION) TABLOLARI ---
    // Bu tablolar, "çoktan çoğa" (many-to-many) ilişkileri yönetir.
    // Örn: Bir kitabın birden çok yazarı olabilir, bir yazarın da birden çok kitabı.

    // Links books to their authors.
    batch.execute(
        'CREATE TABLE Book_Author(b_id INTEGER NOT NULL, a_id INTEGER NOT NULL, PRIMARY KEY (b_id, a_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (a_id) REFERENCES Author(a_id) ON DELETE CASCADE)');
    // Links books to their publishers.
    batch.execute(
        'CREATE TABLE Book_Publisher(b_id INTEGER NOT NULL, pbl_id INTEGER NOT NULL, PRIMARY KEY (b_id, pbl_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (pbl_id) REFERENCES Publisher(pbl_id) ON DELETE CASCADE)');
    // Links books to their subjects.
    batch.execute(
        'CREATE TABLE Book_Subject(b_id INTEGER NOT NULL, sbj_id INTEGER NOT NULL, PRIMARY KEY (b_id, sbj_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (sbj_id) REFERENCES Subject(sbj_id) ON DELETE CASCADE)');
    // Links books to people mentioned in them.
    batch.execute(
        'CREATE TABLE Book_Person(b_id INTEGER NOT NULL, prs_id INTEGER NOT NULL, PRIMARY KEY (b_id, prs_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (prs_id) REFERENCES Person(prs_id) ON DELETE CASCADE)');
    // Links books to places mentioned in them.
    batch.execute(
        'CREATE TABLE Book_Place(b_id INTEGER NOT NULL, plc_id INTEGER NOT NULL, PRIMARY KEY (b_id, plc_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (plc_id) REFERENCES Place(plc_id) ON DELETE CASCADE)');
    // Links books to time periods mentioned in them.
    batch.execute(
        'CREATE TABLE Book_Time(b_id INTEGER NOT NULL, t_id INTEGER NOT NULL, PRIMARY KEY (b_id, t_id), FOREIGN KEY (b_id) REFERENCES Books(b_id) ON DELETE CASCADE, FOREIGN KEY (t_id) REFERENCES Time(t_id) ON DELETE CASCADE)');

    // --- BAŞLANGIÇ VERİSİ ---

    // Creates a default user so the app can function without a full login system.
    batch.insert('User', {'u_userName': 'defaultUser'});

    // Tüm komutları veritabanında çalıştır.
    await batch.commit(noResult: true);
    debugPrint("--- TÜM TABLOLAR BAŞARIYLA OLUŞTURULDU (ANALYTICS ŞEMASI) ---");
  }
}
