import 'dart:convert';
import 'package:http/http.dart' as http;

// Bu sınıfta değişiklik yok.
class ApiBookSearchResult {
  final String workKey;
  final String title;
  final List<String> authors;
  final int? coverId;

  ApiBookSearchResult({required this.workKey, required this.title, required this.authors, this.coverId});

  factory ApiBookSearchResult.fromJson(Map<String, dynamic> json) {
    return ApiBookSearchResult(
      workKey: json['key'],
      title: json['title'],
      authors: (json['author_name'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      coverId: json['cover_i'],
    );
  }
}

// Bu sınıfta değişiklik yok.
class ApiBookDetails {
  final String? description;
  final List<String> publishers;
  final List<String> subjects;
  final List<String> people;
  final List<String> places;
  final List<String> times;
  final int? totalPages; // YENİ ALAN

  ApiBookDetails({this.description, required this.publishers, required this.subjects, required this.people, required this.places, required this.times, this.totalPages});

  factory ApiBookDetails.fromJson({
    required Map<String, dynamic> workJson,
    required List<String> fetchedPublishers,
    required int? fetchedPageCount, // YENİ PARAMETRE
  }) {
    String desc = '';
    if (workJson['description'] is String) { desc = workJson['description']; } 
    else if (workJson['description'] is Map && workJson['description']['value'] != null) { desc = workJson['description']['value']; }
    
    return ApiBookDetails(
      description: desc,
      publishers: fetchedPublishers,
      subjects: (workJson['subjects'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      people: (workJson['subject_people'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      places: (workJson['subject_places'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      times: (workJson['subject_times'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      totalPages: fetchedPageCount, // YENİ ATAMA
    );
  }
}


class OpenLibraryService {
  final String _searchUrl = 'https://openlibrary.org/search.json';
  final String _baseUrl = 'https://openlibrary.org';

  // Bu metot değişmedi.
  Future<List<ApiBookSearchResult>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    const String fields = 'key,title,author_name,cover_i';
    final uri = Uri.parse('$_searchUrl?q=${Uri.encodeComponent(query)}&fields=$fields');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['docs'] as List).map((doc) => ApiBookSearchResult.fromJson(doc)).toList();
      } else {
        throw Exception('API Search Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error during search: $e');
    }
  }

  // === BU METOT HATAYI GİDERMEK İÇİN TAMAMEN GÜNCELLENDİ ===
  Future<ApiBookDetails?> getBookDetails(String workKey) async {
    if (!workKey.startsWith('/works/')) return null;
    try {
      final workUri = Uri.parse('$_baseUrl$workKey.json');
      final workResponse = await http.get(workUri);
      if (workResponse.statusCode != 200) return null;
      final workJson = json.decode(workResponse.body);
      
      final editionsUri = Uri.parse('$_baseUrl$workKey/editions.json?limit=5');
      final editionsResponse = await http.get(editionsUri);
      List<String> fetchedPublishers = [];
      int? fetchedPageCount; // Sayfa sayısını tutacak değişken

      if (editionsResponse.statusCode == 200) {
        final editionsJson = json.decode(editionsResponse.body);
        final entries = editionsJson['entries'] as List<dynamic>? ?? [];
        for (var edition in entries) {
          // Yayıncıyı bul
          if (fetchedPublishers.isEmpty) {
            final publishers = edition['publishers'] as List<dynamic>?;
            if (publishers != null && publishers.isNotEmpty) {
              fetchedPublishers = publishers.map((p) => p.toString()).toList();
            }
          }
          // Sayfa sayısını bul
          if (fetchedPageCount == null) {
            final pageCount = edition['number_of_pages'];
            if (pageCount is int && pageCount > 0) {
              fetchedPageCount = pageCount;
            }
          }
          // İkisini de bulduysak döngüden çıkabiliriz.
          if (fetchedPublishers.isNotEmpty && fetchedPageCount != null) break;
        }
      }

      return ApiBookDetails.fromJson(
        workJson: workJson,
        fetchedPublishers: fetchedPublishers,
        fetchedPageCount: fetchedPageCount, // Yeni parametreyi geç
      );
    } catch (e) {
      print("Could not fetch complete details for $workKey: $e");
      return null;
    }
  }
}
