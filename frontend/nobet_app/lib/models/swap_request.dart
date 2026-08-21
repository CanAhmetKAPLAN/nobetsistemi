class SwapRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String targetUserId;
  final String targetUserName;
  final String requesterDutyId;
  final String requesterDutyDate;
  final String? targetDutyId;
  final String? targetDutyDate;
  final String reason;
  final String status;
  final String createdAt;

  const SwapRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.targetUserId,
    required this.targetUserName,
    required this.requesterDutyId,
    required this.requesterDutyDate,
    this.targetDutyId,
    this.targetDutyDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory SwapRequest.fromJson(Map<String, dynamic> j) => SwapRequest(
        id: j['id'],
        requesterId: j['requesterId'],
        requesterName: j['requesterName'] ?? '',
        targetUserId: j['targetUserId'],
        targetUserName: j['targetUserName'] ?? '',
        requesterDutyId: j['requesterDutyId'],
        requesterDutyDate: j['requesterDutyDate'] ?? '',
        targetDutyId: j['targetDutyId'],
        targetDutyDate: j['targetDutyDate'],
        reason: j['reason'] ?? '',
        status: j['status'] ?? 'Pending',
        createdAt: j['createdAt'] ?? '',
      );
}
