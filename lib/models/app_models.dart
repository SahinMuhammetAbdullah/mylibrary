class Book {
  final int id;
  final String? name;
  final String? description;
  final String? coverUrl;
  final String? oWorkId;
  final int? totalPages; // YENİ ALAN

  final List<Author> authors;
  final List<Publisher> publishers;
  final List<Subject> subjects;
  final List<Person> people;
  final List<Place> places;
  final List<Time> times;

  Book({
    required this.id, this.name, this.description, this.coverUrl, this.oWorkId,
    this.authors = const [], this.publishers = const [], this.subjects = const [],
    this.people = const [], this.places = const [], this.times = const [], this.totalPages,
  });
  
  String get authorString => authors.map((a) => a.name).join(', ');
}

class Author {
  final int id;
  final String name;
  Author({required this.id, required this.name});
}

class Publisher {
  final int id;
  final String name;
  Publisher({required this.id, required this.name});
}

class Subject {
  final int id;
  final String name;
  Subject({required this.id, required this.name});
}

class Person {
  final int id;
  final String name;
  Person({required this.id, required this.name});
}

class Place {
  final int id;
  final String name;
  Place({required this.id, required this.name});
}

class Time {
  final int id;
  final String name;
  Time({required this.id, required this.name});
}

class Note {
  final int id;
  final int bookId;
  final String text;
  final String bookTitle;

  Note({required this.id, required this.bookId, required this.text, required this.bookTitle});
}
