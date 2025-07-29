class Note {
  final int id;
  final int bookId;
  final String text;
  final String bookTitle;
  final int? pageNumber;
  Note({
    required this.id,
    required this.bookId,
    required this.text,
    required this.bookTitle,
    this.pageNumber,
  });
}
