class User {
  final String id;
  final String name;
  final String email;
  final String createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        createdAt: j['createdAt'] ?? '',
      );
}
