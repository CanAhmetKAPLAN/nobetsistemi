class Duty {
  final String id;
  final String userId;
  final String userName;
  final String date;
  final bool isAutoAssigned;
  final String? notes;
  final String createdAt;

  const Duty({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.isAutoAssigned,
    this.notes,
    required this.createdAt,
  });

  factory Duty.fromJson(Map<String, dynamic> j) => Duty(
        id: j['id'],
        userId: j['userId'],
        userName: j['userName'] ?? '',
        date: j['date'],
        isAutoAssigned: j['isAutoAssigned'] ?? false,
        notes: j['notes'],
        createdAt: j['createdAt'] ?? '',
      );
}
