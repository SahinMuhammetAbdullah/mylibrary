import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiBookSearchResult {
  final String workKey; // e.g., /works/OL45883W
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

class ApiBookDetails {
  final List<String> subjects;
  final List<String> publishers;
  final String? description;

  ApiBookDetails({required this.subjects, required this.publishers, this.description});

  factory ApiBookDetails.fromJson(Map<String, dynamic> json) {
    String desc = '';
    if (json['description'] is String) {
      desc = json['description'];
    } else if (json['description'] is Map && json['description']['value'] != null) {
      desc = json['description']['value'];
    }
    return ApiBookDetails(
      subjects: (json['subjects'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      publishers: (json['publishers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      description: desc,
    );
  }
}

class OpenLibraryService {
  final String _searchUrl = 'https://openlibrary.org/search.json';
  final String _baseUrl = 'https://openlibrary.org';

  Future<List<ApiBookSearchResult>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    final uri = Uri.parse('$_searchUrl?q=${Uri.encodeComponent(query)}&fields=key,title,author_name,cover_i');
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

  Future<ApiBookDetails?> getBookDetails(String workKey) async {
    if (!workKey.startsWith('/works/')) return null;
    final uri = Uri.parse('$_baseUrl$workKey.json');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return ApiBookDetails.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print("Could not fetch details for $workKey: $e");
      return null;
    }
  }
}
