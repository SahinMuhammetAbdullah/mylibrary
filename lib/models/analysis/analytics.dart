class Analytics {
  final int? id;
  final int userId;
  final int bookId;
  String status; // 'wishlist', 'reading', 'completed'
  int? rating;
  int currentPage;
  DateTime? startedAt;
  DateTime? finishedAt;
  DateTime? lastReadAt;

  Analytics({
    this.id,
    required this.userId,
    required this.bookId,
    this.status = 'wishlist',
    this.rating,
    this.currentPage = 0,
    this.startedAt,
    this.finishedAt,
    this.lastReadAt,
  });

  factory Analytics.fromMap(Map<String, dynamic> map) {
    return Analytics(
      id: map['a_id'],
      userId: map['u_id'],
      bookId: map['b_id'],
      status: map['a_status'],
      rating: map['a_rating'],
      currentPage: map['a_currentPage'] ?? 0,
      startedAt: map['a_startedAt'] != null
          ? DateTime.parse(map['a_startedAt'])
          : null,
      finishedAt: map['a_finishedAt'] != null
          ? DateTime.parse(map['a_finishedAt'])
          : null,
      lastReadAt: map['a_lastReadAt'] != null
          ? DateTime.parse(map['a_lastReadAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'a_id': id,
      'u_id': userId,
      'b_id': bookId,
      'a_status': status,
      'a_rating': rating,
      'a_currentPage': currentPage,
      'a_startedAt': startedAt?.toIso8601String(),
      'a_finishedAt': finishedAt?.toIso8601String(),
      'a_lastReadAt': lastReadAt?.toIso8601String(),
    };
  }
}
