import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';
import '../services/open_library_service.dart';
import '../models/app_models.dart' as app_models;

class BookService with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final OpenLibraryService _api = OpenLibraryService();
  final int _currentUserId = 1;

  List<app_models.Book> _libraryBooks = [];
  List<app_models.Book> get libraryBooks => _libraryBooks;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  BookService() {
    loadLibraryBooks();
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
        final newBookId = await txn.insert('Books', {'b_name': apiBook.title, 'b_coverUrl': apiBook.coverId != null ? 'https://covers.openlibrary.org/b/id/${apiBook.coverId}-M.jpg' : null, 'b_description': details?.description, 'b_oWorkId': apiBook.workKey});
        for (String name in apiBook.authors) {
          int id = await _getOrInsert(txn, 'Author', 'a_name', 'a_id', name);
          await txn.insert('Book_Author', {'b_id': newBookId, 'a_id': id});
        }
        if (details != null) {
          for (String name in details.publishers) {
            int id = await _getOrInsert(txn, 'Publisher', 'pbl_name', 'pbl_id', name);
            await txn.insert('Book_Publisher', {'b_id': newBookId, 'pbl_id': id});
          }
          for (String name in details.subjects) {
            int id = await _getOrInsert(txn, 'Subject', 'sbj_name', 'sbj_id', name);
            await txn.insert('Book_Subject', {'b_id': newBookId, 'sbj_id': id});
          }
          for (String name in details.people) {
            int id = await _getOrInsert(txn, 'Person', 'prs_name', 'prs_id', name);
            await txn.insert('Book_Person', {'b_id': newBookId, 'prs_id': id});
          }
          for (String name in details.places) {
            int id = await _getOrInsert(txn, 'Place', 'plc_name', 'plc_id', name);
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
    final libraryEntry = await db.query('Library', where: 'b_id = ? AND u_id = ?', whereArgs: [bookId, _currentUserId]);
    if (libraryEntry.isEmpty) {
      await db.insert('Library', {'u_id': _currentUserId, 'b_id': bookId, 'b_addLibAt': DateTime.now().toIso8601String()});
      await loadLibraryBooks();
      return true;
    }
    return false;
  }

  Future<app_models.Book?> getBookDetailsById(int bookId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> bookMaps = await db.query('Books', where: 'b_id = ?', whereArgs: [bookId], limit: 1);
    if (bookMaps.isEmpty) return null;
    final bookMap = bookMaps.first;
    Future<List<T>> getRelatedItems<T>({required String tableName, required String junctionTable, required String idColumn, required T Function(Map<String, dynamic>) fromMap}) async {
      final maps = await db.rawQuery('SELECT T.* FROM $tableName T INNER JOIN $junctionTable J ON T.$idColumn = J.$idColumn WHERE J.b_id = ?', [bookId]);
      return maps.map((m) => fromMap(m)).toList();
    }
    final authors = await getRelatedItems<app_models.Author>(tableName: 'Author', junctionTable: 'Book_Author', idColumn: 'a_id', fromMap: (m) => app_models.Author(id: m['a_id'] as int, name: m['a_name'] as String));
    final publishers = await getRelatedItems<app_models.Publisher>(tableName: 'Publisher', junctionTable: 'Book_Publisher', idColumn: 'pbl_id', fromMap: (m) => app_models.Publisher(id: m['pbl_id'] as int, name: m['pbl_name'] as String));
    final subjects = await getRelatedItems<app_models.Subject>(tableName: 'Subject', junctionTable: 'Book_Subject', idColumn: 'sbj_id', fromMap: (m) => app_models.Subject(id: m['sbj_id'] as int, name: m['sbj_name'] as String));
    final people = await getRelatedItems<app_models.Person>(tableName: 'Person', junctionTable: 'Book_Person', idColumn: 'prs_id', fromMap: (m) => app_models.Person(id: m['prs_id'] as int, name: m['prs_name'] as String));
    final places = await getRelatedItems<app_models.Place>(tableName: 'Place', junctionTable: 'Book_Place', idColumn: 'plc_id', fromMap: (m) => app_models.Place(id: m['plc_id'] as int, name: m['plc_name'] as String));
    final times = await getRelatedItems<app_models.Time>(tableName: 'Time', junctionTable: 'Book_Time', idColumn: 't_id', fromMap: (m) => app_models.Time(id: m['t_id'] as int, name: m['t_name'] as String));

    return app_models.Book(id: bookId, name: bookMap['b_name'] as String?, coverUrl: bookMap['b_coverUrl'] as String?, description: bookMap['b_description'] as String?, oWorkId: bookMap['b_oWorkId'] as String?, authors: authors, publishers: publishers, subjects: subjects, people: people, places: places, times: times);
  }
  
  // --- Değişmeyen diğer metotlar ---
  Future<void> loadLibraryBooks() async {
    _isLoading = true; notifyListeners();
    final db = await _db.database;
    final List<Map<String, dynamic>> bookMaps = await db.rawQuery('SELECT B.* FROM Books B INNER JOIN Library L ON B.b_id = L.b_id WHERE L.u_id = ? ORDER BY L.l_id DESC', [_currentUserId]);
    if (bookMaps.isEmpty) { _libraryBooks = []; _isLoading = false; notifyListeners(); return; }
    final bookIds = bookMaps.map((m) => m['b_id'] as int).toList();
    final List<Map<String, dynamic>> authorRelationMaps = await db.rawQuery('SELECT BA.b_id, A.a_id, A.a_name FROM Author A INNER JOIN Book_Author BA ON A.a_id = BA.a_id WHERE BA.b_id IN (${bookIds.map((_) => '?').join(',')})', bookIds);
    final Map<int, List<app_models.Author>> authorsByBookId = {};
    for (var map in authorRelationMaps) { final bookId = map['b_id'] as int; final author = app_models.Author(id: map['a_id'] as int, name: map['a_name'] as String); (authorsByBookId[bookId] ??= []).add(author); }
    List<app_models.Book> loadedBooks = [];
    for (var bookMap in bookMaps) { final bookId = bookMap['b_id'] as int; loadedBooks.add(app_models.Book(id: bookId, name: bookMap['b_name'] as String?, coverUrl: bookMap['b_coverUrl'] as String?, oWorkId: bookMap['b_oWorkId'] as String?, authors: authorsByBookId[bookId] ?? [])); }
    _libraryBooks = loadedBooks; _isLoading = false; notifyListeners();
  }
  Future<List<app_models.Note>> getNotesForBook(int bookId) async { final db = await _db.database; final noteMaps = await db.query('Notes', where: 'b_id = ?', whereArgs: [bookId], orderBy: 'n_id DESC'); return noteMaps.map((m) => app_models.Note(id: m['n_id'] as int, bookId: m['b_id'] as int, text: m['n_text'] as String, bookTitle: '')).toList(); }
  Future<void> addNoteForBook(String text, int bookId) async { final db = await _db.database; await db.insert('Notes', {'u_id': _currentUserId, 'b_id': bookId, 'n_text': text}); }
  Future<void> deleteNote(int noteId) async { final db = await _db.database; await db.delete('Notes', where: 'n_id = ?', whereArgs: [noteId]); }
  Future<app_models.Book?> findBookInLibraryByWorkId(String workId) async { final db = await _db.database; final List<Map<String, dynamic>> results = await db.rawQuery('SELECT B.* FROM Books B INNER JOIN Library L ON B.b_id = L.b_id WHERE L.u_id = ? AND B.b_oWorkId = ?', [_currentUserId, workId]); if (results.isEmpty) return null; final bookMap = results.first; return app_models.Book(id: bookMap['b_id'] as int, name: bookMap['b_name'] as String?, oWorkId: bookMap['b_oWorkId'] as String?); }
  Future<int> _getOrInsert(DatabaseExecutor txn, String table, String column, String idColumn, String value) async { final results = await txn.query(table, columns: [idColumn], where: '$column = ?', whereArgs: [value], limit: 1); if (results.isNotEmpty) return results.first[idColumn] as int; return await txn.insert(table, {column: value}); }
}