class Group {
  final String id;
  final String name;
  final int memberCount;
  final String myRole;
  final String createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.myRole,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: j['id'],
        name: j['name'],
        memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
        myRole: j['myRole'] ?? 'Member',
        createdAt: j['createdAt'] ?? '',
      );

  bool get isAdmin => myRole == 'Admin';
}
