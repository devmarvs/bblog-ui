import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/user.dart';

class UserRepository {
  final Dio dio;
  UserRepository(this.dio);

  Future<UserModel> getUser(String userId) async {
    final res = await dio.get(ApiPaths.user(userId));
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }
}
