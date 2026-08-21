class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String? reviewedById;
  final String createdAt;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewedById,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: j['id'],
        userId: j['userId'],
        userName: j['userName'] ?? '',
        startDate: j['startDate'],
        endDate: j['endDate'],
        reason: j['reason'] ?? '',
        status: j['status'] ?? 'Pending',
        reviewedById: j['reviewedById'],
        createdAt: j['createdAt'] ?? '',
      );
}
