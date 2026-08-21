class GroupMembership {
  final String userId;
  final String userName;
  final String userEmail;
  final String role;
  final double score;
  final bool isActive;
  final String joinedAt;

  const GroupMembership({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.score,
    required this.isActive,
    required this.joinedAt,
  });

  factory GroupMembership.fromJson(Map<String, dynamic> j) => GroupMembership(
        userId: j['userId'],
        userName: j['userName'] ?? '',
        userEmail: j['userEmail'] ?? '',
        role: j['role'] ?? 'Member',
        score: (j['score'] as num?)?.toDouble() ?? 0.0,
        isActive: j['isActive'] ?? true,
        joinedAt: j['joinedAt'] ?? '',
      );

  bool get isAdmin => role == 'Admin';
}
