class StatsData {
  final int totalBooks;
  final int booksRead;
  final int pagesRead;
  final Map<String, int>
      booksReadByPeriod; // 'daily', 'weekly', 'monthly', 'yearly'

  StatsData({
    this.totalBooks = 0,
    this.booksRead = 0,
    this.pagesRead = 0,
    required this.booksReadByPeriod,
  });
}
