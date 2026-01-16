class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt,
    };
  }
}
