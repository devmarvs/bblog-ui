class ApiPaths {
  static const String base = '/bblog';
  static const String login = '$base/login';
  static const String userCreate = '$base/user/create';
  // Primary endpoint for resending verification.
  static const String emailVerificationRequest = '$base/user/verify-email';
  // Aliases supported by the backend.
  static const String emailVerificationRequestLegacy =
      '$base/user/verify-email/request';
  static const String emailVerificationResend = '$base/user/resend-verification';
  static const String emailVerificationConfirm =
      '$base/user/verify-email/confirm';
  static const String passwordForgot = '$base/user/password/forgot';
  static const String passwordReset = '$base/user/password/reset';
  static String user(String id) => '$base/user/$id';
  static String userSubUsers(String userId) => '$base/user/$userId/subuser';
  static const String subUserLog = '$base/subuser/log';
  static String subUserLogs(String userId, String subUserId) =>
      '$base/user/$userId/subuser/$subUserId/log';
  static const String logTypes = '$base/log/types';
  static const String userTypes = '$base/user/types';
}

/// 👇 Change this to your deployed API origin (include scheme & host, optional port)
/// Examples:
/// const kApiBaseUrl = 'https://api.example.com';
/// const kApiBaseUrl = 'http://10.0.2.2:8080'; // Android emulator to host
/// const kApiBaseUrl = 'http://localhost:8080'; // iOS simulator to host
const String kApiBaseUrl = 'https://api.devmarvs.com';
