import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/sub_user.dart';

class SubUserRepository {
  final Dio dio;
  SubUserRepository(this.dio);

  Future<List<SubUserModel>> list(String userId) async {
    final res = await dio.get(ApiPaths.userSubUsers(userId));
    final payload = res.data;
    final list = _unwrapList(payload);
    return list
        .map((e) => SubUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(
    String userId, {
    required String name,
    required int userTypeId,
  }) async {
    await dio.post(
      ApiPaths.userSubUsers(userId),
      data: {
        'name': name,
        'user_type_id': userTypeId,
      },
    );
  }

  List<dynamic> _unwrapList(
    dynamic payload, {
    Set<int>? visited,
  }) {
    visited ??= <int>{};
    if (payload == null) return const [];
    final identity = payload.hashCode;
    if (!visited.add(identity)) return const [];

    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      if (_looksLikeSubUser(payload)) {
        return [payload];
      }

      const preferredKeys = [
        'data',
        'items',
        'results',
        'subUsers',
        'sub_users',
        'subusers',
        'subUser',
        'sub_user',
        'children',
      ];

      for (final key in preferredKeys) {
        if (!payload.containsKey(key)) continue;
        final nested = _unwrapList(
          payload[key],
          visited: visited,
        );
        if (nested.isNotEmpty) {
          return nested;
        }
      }

      for (final value in payload.values) {
        final nested = _unwrapList(
          value,
          visited: visited,
        );
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return const [];
  }

  bool _looksLikeSubUser(Map<String, dynamic> payload) {
    const idKeys = [
      'subUserId',
      'sub_user_id',
      'subUserID',
      'sub_userid',
      'subuserId',
      'subuser_id',
      'id',
    ];
    final hasId = idKeys.any(payload.containsKey);
    final hasName = payload.containsKey('name') || payload.containsKey('title');
    return hasId && hasName;
  }
}
