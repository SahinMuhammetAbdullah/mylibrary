// lib/services/book_service.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:my_library/helpers/database_helper.dart';
import 'package:my_library/models/models.dart' as app_models;
import 'package:my_library/services/open_library_service.dart';
import 'package:my_library/helpers/data_notifier.dart';
import 'package:my_library/models/analysis/stats_data.dart';

/// Bu servis, uygulama mantığı ile veritabanı arasındaki tüm işlemleri yönetir.
/// Kitap ekleme/silme, ilerleme güncelleme, not yönetimi ve istatistik hesaplama gibi
/// tüm merkezi işlevler burada bulunur.
class BookService with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final OpenLibraryService _api = OpenLibraryService();
  final int _currentUserId = 1; // Varsayılan kullanıcı ID'si

  List<app_models.Book> _libraryBooks = [];
  List<app_models.Book> get libraryBooks => _libraryBooks;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  BookService() {
    loadLibraryBooks();
  }

  // --- KÜTÜPHANE YÖNETİMİ ---

  /// Kullanıcının kütüphanesindeki tüm kitapları ve onlara bağlı analitik verilerini yükler.
  Future<void> loadLibraryBooks() async {
    _isLoading = true;
    notifyListeners();
    final db = await _db.database;
    final bookMaps = await db.rawQuery('''
      SELECT B.*, A.* FROM Books B
      JOIN Analytics A ON B.b_id = A.b_id
      WHERE A.u_id = ?
      ORDER BY A.a_lastReadAt DESC, B.b_name ASC
    ''', [_currentUserId]);

    if (bookMaps.isEmpty) {
      _libraryBooks = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final bookIds = bookMaps.map((m) => m['b_id'] as int).toList();
    final authorRelationMaps = await db.rawQuery(
        'SELECT BA.b_id, A.a_id, A.a_name FROM Author A INNER JOIN Book_Author BA ON A.a_id = BA.a_id WHERE BA.b_id IN (${bookIds.map((_) => '?').join(',')})',
        bookIds);

    final Map<int, List<app_models.Author>> authorsByBookId = {};
    for (var map in authorRelationMaps) {
      final bookId = map['b_id'] as int;
      final author = app_models.Author(
          id: map['a_id'] as int, name: map['a_name'] as String);
      (authorsByBookId[bookId] ??= []).add(author);
    }

    List<app_models.Book> loadedBooks = [];
    for (var bookMap in bookMaps) {
      final bookId = bookMap['b_id'] as int;
      loadedBooks.add(app_models.Book(
        id: bookId,
        name: bookMap['b_name'] as String?,
        oWorkId: bookMap['b_oWorkId'] as String?,
        description: bookMap['b_description'] as String?,
        coverUrl: bookMap['b_coverUrl'] as String?,
        totalPages: bookMap['b_totalPages'] as int?,
        publishDate: bookMap['b_publishDate'] as String?,
        authors: authorsByBookId[bookId] ?? [],
        analytics: app_models.Analytics.fromMap(bookMap),
      ));
    }
    _libraryBooks = loadedBooks;
    _isLoading = false;
    notifyListeners();
  }

  /// API'dan gelen bir kitabı kütüphaneye ekler.
  Future<bool> addBookFromApi(ApiBookSearchResult apiBook) async {
    final db = await _db.database;
    final existingBooks = await db.query('Books',
        where: 'b_oWorkId = ?', whereArgs: [apiBook.workKey], limit: 1);
    int bookId;
    if (existingBooks.isNotEmpty) {
      bookId = existingBooks.first['b_id'] as int;
    } else {
      final details = await _api.getBookDetails(apiBook.workKey);
      bookId = await db.transaction((txn) async {
        final newBookId = await txn.insert('Books', {
          'b_name': apiBook.title,
          'b_coverUrl': apiBook.coverId != null
              ? 'https://covers.openlibrary.org/b/id/${apiBook.coverId}-M.jpg'
              : null,
          'b_description': details?.description,
          'b_oWorkId': apiBook.workKey,
          'b_totalPages': details?.totalPages,
          'b_publishDate': details?.publishDate
        });
        for (String name in apiBook.authors) {
          int id = await _getOrInsert(txn, 'Author', 'a_name', 'a_id', name);
          await txn.insert('Book_Author', {'b_id': newBookId, 'a_id': id});
        }
        if (details != null) {
          for (String name in details.publishers) {
            int id = await _getOrInsert(
                txn, 'Publisher', 'pbl_name', 'pbl_id', name);
            await txn
                .insert('Book_Publisher', {'b_id': newBookId, 'pbl_id': id});
          }
          for (String name in details.subjects) {
            int id =
                await _getOrInsert(txn, 'Subject', 'sbj_name', 'sbj_id', name);
            await txn.insert('Book_Subject', {'b_id': newBookId, 'sbj_id': id});
          }
          for (String name in details.people) {
            int id =
                await _getOrInsert(txn, 'Person', 'prs_name', 'prs_id', name);
            await txn.insert('Book_Person', {'b_id': newBookId, 'prs_id': id});
          }
          for (String name in details.places) {
            int id =
                await _getOrInsert(txn, 'Place', 'plc_name', 'plc_id', name);
            await txn.insert('Book_Place', {'b_id': newBookId, 'plc_id': id});
          }
          for (String name in details.times) {
            int id = await _getOrInsert(txn, 'Time', 't_name', 't_id', name);
            await txn.insert('Book_Time', {'b_id': newBookId, 't_id': id});
          }
        }
        return newBookId;
      });
    }
    final analyticsEntry = await db.query('Analytics',
        where: 'b_id = ? AND u_id = ?', whereArgs: [bookId, _currentUserId]);
    if (analyticsEntry.isEmpty) {
      final newAnalytics = app_models.Analytics(
          userId: _currentUserId,
          bookId: bookId,
          status: 'wishlist',
          currentPage: 0,
          lastReadAt: DateTime.now());
      await db.insert('Analytics', newAnalytics.toMap());
      await loadLibraryBooks();
      notifyDataChanged();
      return true;
    }
    return false;
  }

  /// Bir kitabı ve ona bağlı tüm verileri siler.
  Future<void> deleteBook(int bookId) async {
    final db = await _db.database;
    await db.delete('Books', where: 'b_id = ?', whereArgs: [bookId]);
    await loadLibraryBooks();
    notifyDataChanged();
  }

  // --- ANALİTİK VE İLERLEME YÖNETİMİ ---

  /// Bir kitabın analitik verilerini günceller.
  Future<void> updateAnalytics(app_models.Analytics analytics) async {
    final db = await _db.database;
    analytics.lastReadAt = DateTime.now();
    await db.update('Analytics', analytics.toMap(),
        where: 'a_id = ?', whereArgs: [analytics.id]);
    notifyDataChanged();
  }

  /// Bir kitabın okuma durumunu değiştirir.
  Future<void> changeBookStatus(
      app_models.Analytics analytics, String newStatus) async {
    analytics.status = newStatus;
    final now = DateTime.now();
    if (newStatus == 'reading' && analytics.startedAt == null) {
      analytics.startedAt = now;
    }
    if (newStatus == 'completed') {
      analytics.finishedAt = now;
      final db = await _db.database;
      final bookData = await db.query('Books',
          columns: ['b_totalPages'],
          where: 'b_id = ?',
          whereArgs: [analytics.bookId]);
      if (bookData.isNotEmpty) {
        analytics.currentPage =
            bookData.first['b_totalPages'] as int? ?? analytics.currentPage;
      }
    }
    await updateAnalytics(analytics);
    await loadLibraryBooks();
    notifyDataChanged();
  }

  // --- VERİ ÇEKME METOTLARI ---

  /// ID'ye göre tek bir kitabın tüm detaylarını getirir.
  Future<app_models.Book?> getBookDetailsById(int bookId) async {
    final db = await _db.database;
    // Books ve Analytics tablolarını JOIN ile birleştirerek tek seferde tüm veriyi çekiyoruz.
    final List<Map<String, dynamic>> bookMaps = await db.rawQuery('''
      SELECT B.*, A.* 
      FROM Books B 
      JOIN Analytics A ON B.b_id = A.b_id 
      WHERE B.b_id = ? AND A.u_id = ?
    ''', [bookId, _currentUserId]);

    if (bookMaps.isEmpty) return null;
    final bookMap = bookMaps.first;

    // Yardımcı metot (Değişiklik yok)
    Future<List<T>> getRelatedItems<T>(
        {required String tableName,
        required String junctionTable,
        required String idColumn,
        required T Function(Map<String, dynamic>) fromMap}) async {
      final maps = await db.rawQuery(
          'SELECT T.* FROM $tableName T INNER JOIN $junctionTable J ON T.$idColumn = J.$idColumn WHERE J.b_id = ?',
          [bookId]);
      return maps.map((m) => fromMap(m)).toList();
    }

    // İlişkisel verileri çekme (Değişiklik yok)
    final authors = await getRelatedItems<app_models.Author>(
        tableName: 'Author',
        junctionTable: 'Book_Author',
        idColumn: 'a_id',
        fromMap: (m) => app_models.Author(
            id: m['a_id'] as int, name: m['a_name'] as String));
    final publishers = await getRelatedItems<app_models.Publisher>(
        tableName: 'Publisher',
        junctionTable: 'Book_Publisher',
        idColumn: 'pbl_id',
        fromMap: (m) => app_models.Publisher(
            id: m['pbl_id'] as int, name: m['pbl_name'] as String));
    final subjects = await getRelatedItems<app_models.Subject>(
        tableName: 'Subject',
        junctionTable: 'Book_Subject',
        idColumn: 'sbj_id',
        fromMap: (m) => app_models.Subject(
            id: m['sbj_id'] as int, name: m['sbj_name'] as String));
    final people = await getRelatedItems<app_models.Person>(
        tableName: 'Person',
        junctionTable: 'Book_Person',
        idColumn: 'prs_id',
        fromMap: (m) => app_models.Person(
            id: m['prs_id'] as int, name: m['prs_name'] as String));
    final places = await getRelatedItems<app_models.Place>(
        tableName: 'Place',
        junctionTable: 'Book_Place',
        idColumn: 'plc_id',
        fromMap: (m) => app_models.Place(
            id: m['plc_id'] as int, name: m['plc_name'] as String));
    final times = await getRelatedItems<app_models.Time>(
        tableName: 'Time',
        junctionTable: 'Book_Time',
        idColumn: 't_id',
        fromMap: (m) =>
            app_models.Time(id: m['t_id'] as int, name: m['t_name'] as String));

    // Artık bookMap hem kitap hem de analitik verilerini içerdiği için bu işlem güvenli.
    return app_models.Book(
      id: bookId,
      name: bookMap['b_name'] as String?,
      coverUrl: bookMap['b_coverUrl'] as String?,
      description: bookMap['b_description'] as String?,
      oWorkId: bookMap['b_oWorkId'] as String?,
      totalPages: bookMap['b_totalPages'] as int?,
      publishDate: bookMap['b_publishDate'] as String?,
      authors: authors,
      publishers: publishers,
      subjects: subjects,
      people: people,
      places: places,
      times: times,
      analytics:
          app_models.Analytics.fromMap(bookMap), // Bu artık hata vermeyecek.
    );
  }

  /// Open Library Work ID'sine göre bir kitabın kütüphanede olup olmadığını bulur.
  Future<app_models.Book?> findBookInLibraryByWorkId(String workId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT B.* FROM Books B JOIN Analytics A ON B.b_id = A.b_id WHERE A.u_id = ? AND B.b_oWorkId = ?',
        [_currentUserId, workId]);
    if (results.isEmpty) return null;
    final bookMap = results.first;
    return app_models.Book(
        id: bookMap['b_id'] as int,
        name: bookMap['b_name'] as String?,
        oWorkId: bookMap['b_oWorkId'] as String?);
  }

  // --- İSTATİSTİK YÖNETİMİ ---

  /// Kullanıcının tüm okuma istatistiklerini hesaplar.
  Future<StatsData> getStats() async {
    final db = await _db.database;
    final allAnalytics = await db
        .query('Analytics', where: 'u_id = ?', whereArgs: [_currentUserId]);

    // 1. Tamamlanmış kitapları bul
    final completedBooksAnalytics =
        allAnalytics.where((m) => m['a_status'] == 'completed').toList();
    final booksReadCount = completedBooksAnalytics.length;

    int totalPagesRead = 0;

    // 2. Tamamlanmış kitapların TOPLAM sayfa sayılarını topla
    if (completedBooksAnalytics.isNotEmpty) {
      final bookIds = completedBooksAnalytics.map((m) => m['b_id']).toList();
      final pageCounts = await db.query('Books',
          columns: ['b_totalPages'],
          where: 'b_id IN (${bookIds.map((_) => '?').join(',')})',
          whereArgs: bookIds);
      totalPagesRead += pageCounts.fold(
          0, (sum, map) => sum + (map['b_totalPages'] as int? ?? 0));
    }

    // 3. Okunmakta olan kitapları bul
    final readingBooksAnalytics =
        allAnalytics.where((m) => m['a_status'] == 'reading').toList();

    // 4. Okunmakta olan kitapların MEVCUT sayfa sayılarını (`a_currentPage`) topla
    if (readingBooksAnalytics.isNotEmpty) {
      totalPagesRead += readingBooksAnalytics.fold(
          0, (sum, map) => sum + (map['a_currentPage'] as int? ?? 0));
    }

    // 5. Periyotlara göre tamamlanmış kitap sayılarını hesapla (Bu mantık aynı kalır)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    int booksToday = completedBooksAnalytics
        .where((m) =>
            m['a_finishedAt'] != null &&
            DateTime.parse(m['a_finishedAt'] as String).isAfter(today))
        .length;
    int booksWeek = completedBooksAnalytics
        .where((m) =>
            m['a_finishedAt'] != null &&
            DateTime.parse(m['a_finishedAt'] as String).isAfter(startOfWeek))
        .length;
    int booksMonth = completedBooksAnalytics
        .where((m) =>
            m['a_finishedAt'] != null &&
            DateTime.parse(m['a_finishedAt'] as String).isAfter(startOfMonth))
        .length;
    int booksYear = completedBooksAnalytics
        .where((m) =>
            m['a_finishedAt'] != null &&
            DateTime.parse(m['a_finishedAt'] as String).isAfter(startOfYear))
        .length;

    return StatsData(
      totalBooks: allAnalytics.length,
      booksRead: booksReadCount,
      pagesRead: totalPagesRead,
      booksReadByPeriod: {
        'daily': booksToday,
        'weekly': booksWeek,
        'monthly': booksMonth,
        'yearly': booksYear
      },
    );
  }

  // --- NOT YÖNETİMİ ---

  /// Bir kitaba yeni not ekler.
  Future<void> addNoteForBook(String text, int bookId) async {
    final db = await _db.database;
    await db.insert('Notes', {
      'u_id': _currentUserId,
      'b_id': bookId,
      'n_text': text,
      'n_createdAt': DateTime.now().toIso8601String()
    });
    notifyDataChanged();
  }

  /// Bir notu siler.
  Future<void> deleteNote(int noteId) async {
    final db = await _db.database;
    await db.delete('Notes', where: 'n_id = ?', whereArgs: [noteId]);
    notifyDataChanged();
  }

  /// Belirli bir kitaba ait notları getirir.
  Future<List<app_models.Note>> getNotesForBook(int bookId) async {
    final db = await _db.database;
    final noteMaps = await db.query('Notes',
        where: 'b_id = ? AND u_id = ?',
        whereArgs: [bookId, _currentUserId],
        orderBy: 'n_createdAt DESC');
    return noteMaps
        .map((m) => app_models.Note(
            id: m['n_id'] as int,
            bookId: m['b_id'] as int,
            text: m['n_text'] as String,
            bookTitle: ''))
        .toList();
  }

  /// Tüm notları, ilişkili oldukları kitapların adlarıyla birlikte getirir.
  Future<List<Map<String, dynamic>>> getAllNotesWithBookInfo(
      {String orderBy = 'n.n_createdAt DESC'}) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT 
        n.n_id, 
        n.n_text, 
        n.n_createdAt, 
        b.b_name as bookTitle 
      FROM Notes n 
      JOIN Books b ON n.b_id = b.b_id 
      WHERE n.u_id = ?
      ORDER BY $orderBy
    ''', [_currentUserId]);
  }

  // --- İÇ YARDIMCI METOT ---

  /// Veritabanında bir değerin (örn: yazar adı) olup olmadığını kontrol eder.
  /// Varsa ID'sini döndürür, yoksa ekleyip yeni ID'yi döndürür.
  Future<int> _getOrInsert(DatabaseExecutor txn, String table, String column,
      String idColumn, String value) async {
    final results = await txn.query(table,
        columns: [idColumn],
        where: '$column = ?',
        whereArgs: [value],
        limit: 1);
    if (results.isNotEmpty) {
      return results.first[idColumn] as int;
    }
    return await txn.insert(table, {column: value});
  }
}
