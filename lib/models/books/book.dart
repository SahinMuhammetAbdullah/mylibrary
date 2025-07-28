import 'author.dart';
import 'person.dart';
import 'place.dart';
import 'publisher.dart';
import 'subject.dart';
import 'time.dart';
import '../analysis/analytics.dart'; 

class Book {
  final int id;
  final String? name;
  final String? description;
  final String? coverUrl;
  final String? oWorkId;
  final int? totalPages;
  final String? publishDate;

  final List<Author> authors;
  final List<Publisher> publishers;
  final List<Subject> subjects;
  final List<Person> people;
  final List<Place> places;
  final List<Time> times;

  final Analytics? analytics;
  
  Book({
    required this.id, this.name, this.description, this.coverUrl, this.oWorkId,
    this.totalPages, this.publishDate,
    this.authors = const [], this.publishers = const [], this.subjects = const [],
    this.people = const [], this.places = const [], this.times = const [], this.analytics,
  });
  
  String get authorString => authors.map((a) => a.name).join(', ');
}