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

  ApiBookDetails({this.description, required this.publishers, required this.subjects, required this.people, required this.places, required this.times});

  factory ApiBookDetails.fromJson({
    required Map<String, dynamic> workJson,
    required List<String> fetchedPublishers
  }) {
    String desc = '';
    if (workJson['description'] is String) {
      desc = workJson['description'];
    } else if (workJson['description'] is Map && workJson['description']['value'] != null) {
      desc = workJson['description']['value'];
    }
    return ApiBookDetails(
      description: desc,
      publishers: fetchedPublishers, // Yayıncıyı dışarıdan alıyoruz.
      subjects: (workJson['subjects'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      people: (workJson['subject_people'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      places: (workJson['subject_places'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      times: (workJson['subject_times'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
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
    final uri = Uri.parse('$_searchUrl?q=${Uri.encodeComponent(query)}&fields=$fields&limit=20');
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
      // 1. İstek: Eserin genel detaylarını (açıklama, konular vb.) al.
      final workUri = Uri.parse('$_baseUrl$workKey.json');
      final workResponse = await http.get(workUri);
      if (workResponse.statusCode != 200) return null; // Ana detaylar alınamazsa devam etme.
      final workJson = json.decode(workResponse.body);
      
      // 2. İstek: Eserin baskılarını (yayıncıyı bulmak için) al.
      final editionsUri = Uri.parse('$_baseUrl$workKey/editions.json?limit=5'); // İlk 5 baskıyı kontrol et yeterli
      final editionsResponse = await http.get(editionsUri);
      List<String> fetchedPublishers = [];

      if (editionsResponse.statusCode == 200) {
        final editionsJson = json.decode(editionsResponse.body);
        final entries = editionsJson['entries'] as List<dynamic>? ?? [];
        // Yayıncı bilgisi içeren ilk baskıyı bul ve kullan.
        for (var edition in entries) {
          final publishers = edition['publishers'] as List<dynamic>?;
          if (publishers != null && publishers.isNotEmpty) {
            fetchedPublishers = publishers.map((p) => p.toString()).toList();
            break; // Yayıncıyı bulduk, döngüden çık.
          }
        }
      }

      // 3. İki API isteğinden gelen verileri birleştirerek modeli oluştur.
      return ApiBookDetails.fromJson(
        workJson: workJson,
        fetchedPublishers: fetchedPublishers,
      );

    } catch (e) {
      print("Could not fetch complete details for $workKey: $e");
      return null;
    }
  }
}