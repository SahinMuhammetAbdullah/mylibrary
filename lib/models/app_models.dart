class Book {
  final int id;
  final String? name;
  final String? description;
  final String? coverUrl;
  final String? oWorkId;

  // Joined data
  final List<Author> authors;
  final List<Publisher> publishers;
  final List<Subject> subjects;

  Book({
    required this.id, this.name, this.description, this.coverUrl, this.oWorkId,
    this.authors = const [], this.publishers = const [], this.subjects = const [],
  });
  
  // Helper to get a display-friendly author string
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

class Note {
  final int id;
  final int bookId;
  final String text;
  final String bookTitle; // Joined from Books table

  Note({required this.id, required this.bookId, required this.text, required this.bookTitle});
}
