class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        userId: j['userId'],
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        isRead: j['isRead'] ?? false,
        createdAt: j['createdAt'] ?? '',
      );
}
