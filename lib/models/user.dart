class UserModel {
  final String userId;
  final String username;
  final String email;
  final String? phone;
  final String? country;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    this.phone,
    this.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'].toString(),
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    country: json['country'],
  );
}
