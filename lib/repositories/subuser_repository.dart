import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/sub_user.dart';

class SubUserRepository {
  final Dio dio;
  SubUserRepository(this.dio);

  Future<List<SubUserModel>> list(String userId) async {
    final res = await dio.get(ApiPaths.userSubUsers(userId));
    final data = res.data as List;
    return data
        .map((e) => SubUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(
    String userId, {
    required String name,
    String? description,
  }) async {
    await dio.post(
      ApiPaths.userSubUsers(userId),
      data: {'name': name, if (description != null) 'description': description},
    );
  }
}
