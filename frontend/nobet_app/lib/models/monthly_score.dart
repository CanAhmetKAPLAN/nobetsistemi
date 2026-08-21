class MonthlyScore {
  final String userId;
  final String userName;
  final int year;
  final int month;
  final int score;

  const MonthlyScore({
    required this.userId,
    required this.userName,
    required this.year,
    required this.month,
    required this.score,
  });

  factory MonthlyScore.fromJson(Map<String, dynamic> j) => MonthlyScore(
        userId: j['userId'],
        userName: j['userName'] ?? '',
        year: j['year'],
        month: j['month'],
        score: j['score'],
      );
}
