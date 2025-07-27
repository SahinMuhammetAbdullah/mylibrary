import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';
import '../services/open_library_service.dart';
import '../models/app_models.dart' as app_models;

class BookService with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final OpenLibraryService _api = OpenLibraryService();
  final int _currentUserId = 1; // Default user

  List<app_models.Book> _libraryBooks = [];
  List<app_models.Book> get libraryBooks => _libraryBooks;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  BookService() {
    loadLibraryBooks();
  }

  /// Kütüphanedeki kitapları ve ilişkili verileri (yazarlar vb.)
  /// verimli bir şekilde yükler.
  Future<void> loadLibraryBooks() async {
    _isLoading = true;
    notifyListeners();

    final db = await _db.database;

    // 1. Adım: Kullanıcının kütüphanesindeki tüm kitapları tek bir sorguyla al.
    final List<Map<String, dynamic>> bookMaps = await db.rawQuery('''
      SELECT B.* FROM Books B
      INNER JOIN Library L ON B.b_id = L.b_id
      WHERE L.u_id = ?
      ORDER BY L.l_id DESC
    ''', [_currentUserId]);

    if (bookMaps.isEmpty) {
      _libraryBooks = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 2. Adım: Tüm kitap ID'lerini bir liste haline getir.
    final bookIds = bookMaps.map((m) => m['b_id'] as int).toList();

    // 3. Adım: Bu kitaplara ait TÜM yazarları TEK BİR sorguyla al.
    // Sorguya b_id'yi de dahil ediyoruz ki hangi yazarın hangi kitaba ait olduğunu bilelim.
    final List<Map<String, dynamic>> authorRelationMaps = await db.rawQuery('''
      SELECT BA.b_id, A.a_id, A.a_name 
      FROM Author A 
      INNER JOIN Book_Author BA ON A.a_id = BA.a_id 
      WHERE BA.b_id IN (${bookIds.map((_) => '?').join(',')})
    ''', bookIds);

    // 4. Adım: Yazarları kitap ID'lerine göre bir haritada grupla.
    final Map<int, List<app_models.Author>> authorsByBookId = {};
    for (var map in authorRelationMaps) {
      final bookId = map['b_id'] as int;
      final author = app_models.Author(
        // === HATA DÜZELTME NOKTASI ===
        // Veritabanından gelen 'Object?' tipini 'int' ve 'String'e güvenle dönüştür.
        id: map['a_id'] as int,
        name: map['a_name'] as String,
      );
      // Eğer bu kitap ID'si için liste henüz yoksa oluştur, varsa mevcut listeye ekle.
      (authorsByBookId[bookId] ??= []).add(author);
    }
    
    // Not: Benzer şekilde Publisher ve Subject verileri de toplu olarak çekilebilir.

    // 5. Adım: Kitap listesini oluştururken gruplanmış yazar haritasını kullan.
    List<app_models.Book> loadedBooks = [];
    for (var bookMap in bookMaps) {
      final bookId = bookMap['b_id'] as int;
      loadedBooks.add(app_models.Book(
        id: bookId,
        name: bookMap['b_name'] as String?,
        coverUrl: bookMap['b_coverUrl'] as String?,
        oWorkId: bookMap['b_oWorkId'] as String?,
        description: bookMap['b_description'] as String?,
        // Kitabın yazarlarını haritadan al. Eğer hiç yazarı yoksa boş liste ata.
        authors: authorsByBookId[bookId] ?? [], 
      ));
    }

    _libraryBooks = loadedBooks;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBookFromApi(ApiBookSearchResult apiBook) async {
    final db = await _db.database;
    
    final existingBooks = await db.query('Books', where: 'b_oWorkId = ?', whereArgs: [apiBook.workKey], limit: 1);
    int bookId;

    if (existingBooks.isNotEmpty) {
      bookId = existingBooks.first['b_id'] as int;
    } else {
      final details = await _api.getBookDetails(apiBook.workKey);
      
      bookId = await db.transaction((txn) async {
        final newBookId = await txn.insert('Books', {
          'b_name': apiBook.title,
          'b_coverUrl': apiBook.coverId != null ? 'https://covers.openlibrary.org/b/id/${apiBook.coverId}-M.jpg' : null,
          'b_description': details?.description,
          'b_oWorkId': apiBook.workKey,
        });

        for (String authorName in apiBook.authors) {
          int authorId = await _getOrInsert(txn, 'Author', 'a_name', 'a_id', authorName);
          await txn.insert('Book_Author', {'b_id': newBookId, 'a_id': authorId});
        }

        if (details?.publishers != null) {
          for (String pubName in details!.publishers) {
            int pubId = await _getOrInsert(txn, 'Publisher', 'pbl_name', 'pbl_id', pubName);
            await txn.insert('Book_Publisher', {'b_id': newBookId, 'pbl_id': pubId});
          }
        }
        
        if (details?.subjects != null) {
            for (String subName in details!.subjects) {
                int subId = await _getOrInsert(txn, 'Subject', 'sbj_name', 'sbj_id', subName);
                await txn.insert('Book_Subject', {'b_id': newBookId, 'sbj_id': subId});
            }
        }

        return newBookId;
      });
    }

    final libraryEntry = await db.query('Library', where: 'b_id = ? AND u_id = ?', whereArgs: [bookId, _currentUserId]);
    if (libraryEntry.isEmpty) {
      await db.insert('Library', {'u_id': _currentUserId, 'b_id': bookId, 'b_addLibAt': DateTime.now().toIso8601String()});
      await loadLibraryBooks();
      return true;
    }
    return false;
  }

  Future<int> _getOrInsert(DatabaseExecutor txn, String table, String column, String idColumn, String value) async {
    final results = await txn.query(table, columns: [idColumn], where: '$column = ?', whereArgs: [value], limit: 1);
    if (results.isNotEmpty) {
      return results.first[idColumn] as int;
    }
    return await txn.insert(table, {column: value});
  }

  Future<app_models.Book?> getBookDetailsById(int bookId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> bookMaps = await db.query('Books', where: 'b_id = ?', whereArgs: [bookId], limit: 1);

    if (bookMaps.isEmpty) {
      return null;
    }

    final bookMap = bookMaps.first;

    // Yazarları çek
    final authorMaps = await db.rawQuery('SELECT A.* FROM Author A INNER JOIN Book_Author BA ON A.a_id = BA.a_id WHERE BA.b_id = ?', [bookId]);
    final authors = authorMaps.map((m) => app_models.Author(id: m['a_id'] as int, name: m['a_name'] as String)).toList();
    
    // Yayıncıları çek
    final publisherMaps = await db.rawQuery('SELECT P.* FROM Publisher P INNER JOIN Book_Publisher BP ON P.pbl_id = BP.pbl_id WHERE BP.b_id = ?', [bookId]);
    final publishers = publisherMaps.map((m) => app_models.Publisher(id: m['pbl_id'] as int, name: m['pbl_name'] as String)).toList();

    // Konuları çek
    final subjectMaps = await db.rawQuery('SELECT S.* FROM Subject S INNER JOIN Book_Subject BS ON S.sbj_id = BS.sbj_id WHERE BS.b_id = ?', [bookId]);
    final subjects = subjectMaps.map((m) => app_models.Subject(id: m['sbj_id'] as int, name: m['sbj_name'] as String)).toList();
    
    return app_models.Book(
      id: bookId,
      name: bookMap['b_name'] as String?,
      coverUrl: bookMap['b_coverUrl'] as String?,
      description: bookMap['b_description'] as String?,
      oWorkId: bookMap['b_oWorkId'] as String?,
      authors: authors,
      publishers: publishers,
      subjects: subjects,
    );
  }

  /// Belirli bir kitaba ait notları getirir.
  Future<List<app_models.Note>> getNotesForBook(int bookId) async {
    final db = await _db.database;
    final noteMaps = await db.query('Notes', where: 'b_id = ?', whereArgs: [bookId], orderBy: 'n_id DESC');

    // Burada Note modeli için bir bookTitle'a ihtiyacımız yok, çünkü zaten kitabın içindeyiz.
    // Modeli basit tutmak adına doğrudan Note listesi döndürelim.
    return noteMaps.map((m) => app_models.Note(
      id: m['n_id'] as int,
      bookId: m['b_id'] as int,
      text: m['n_text'] as String,
      bookTitle: '', // Bu ekranda gereksiz
    )).toList();
  }

  /// Veritabanına yeni bir not ekler.
  Future<void> addNoteForBook(String text, int bookId) async {
    final db = await _db.database;
    await db.insert('Notes', {
      'u_id': _currentUserId,
      'b_id': bookId,
      'n_text': text,
    });
    // Not: Bu servis global bir not listesi tutmadığı için notifyListeners() çağırmak
    // yerine, not eklenen ekranın kendi state'ini yenilemesi daha verimli olacaktır.
  }

  /// Veritabanından bir notu siler.
  Future<void> deleteNote(int noteId) async {
    final db = await _db.database;
    await db.delete('Notes', where: 'n_id = ?', whereArgs: [noteId]);
  }

}