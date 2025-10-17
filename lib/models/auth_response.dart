class AuthResponse {
  final String token;
  AuthResponse({required this.token});
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      AuthResponse(token: json['token'] as String);
}
