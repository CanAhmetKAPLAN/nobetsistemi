class AdminVote {
  final String id;
  final String candidateUserId;
  final String candidateName;
  final String initiatedById;
  final String initiatedByName;
  final String status;
  final int yesCount;
  final int noCount;
  final int activeMemberCount;
  final int requiredYesCount;
  final bool? myVote;
  final String createdAt;
  final String? resolvedAt;

  const AdminVote({
    required this.id,
    required this.candidateUserId,
    required this.candidateName,
    required this.initiatedById,
    required this.initiatedByName,
    required this.status,
    required this.yesCount,
    required this.noCount,
    required this.activeMemberCount,
    required this.requiredYesCount,
    required this.myVote,
    required this.createdAt,
    required this.resolvedAt,
  });

  factory AdminVote.fromJson(Map<String, dynamic> j) => AdminVote(
        id: j['id'],
        candidateUserId: j['candidateUserId'],
        candidateName: j['candidateName'] ?? '',
        initiatedById: j['initiatedById'],
        initiatedByName: j['initiatedByName'] ?? '',
        status: j['status'] ?? 'Pending',
        yesCount: j['yesCount'] ?? 0,
        noCount: j['noCount'] ?? 0,
        activeMemberCount: j['activeMemberCount'] ?? 0,
        requiredYesCount: j['requiredYesCount'] ?? 0,
        myVote: j['myVote'],
        createdAt: j['createdAt'] ?? '',
        resolvedAt: j['resolvedAt'],
      );

  bool get isPending => status == 'Pending';
}
