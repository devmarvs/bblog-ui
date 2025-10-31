class AuthResponse {
  final String token;
  final String? userId;

  AuthResponse({required this.token, this.userId});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String;
    String? userId;
    final maybeUserId = json['userId'] ?? json['user_id'] ?? json['uid'];
    if (maybeUserId != null) {
      userId = maybeUserId.toString();
    } else if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      final nestedId = user['userId'] ?? user['id'] ?? user['user_id'];
      if (nestedId != null) {
        userId = nestedId.toString();
      }
    }
    return AuthResponse(token: token, userId: userId);
  }
}
