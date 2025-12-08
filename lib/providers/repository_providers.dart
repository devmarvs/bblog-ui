import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/log_repository.dart';
import '../repositories/log_type_repository.dart';
import '../repositories/subuser_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/user_type_repository.dart';
import '../repositories/version_repository.dart';
import 'auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(dioProvider)),
);

final subUserRepositoryProvider = Provider<SubUserRepository>(
  (ref) => SubUserRepository(ref.watch(dioProvider)),
);

final logsRepositoryProvider = Provider<LogsRepository>(
  (ref) => LogsRepository(ref.watch(dioProvider)),
);

final logTypeRepositoryProvider = Provider<LogTypeRepository>(
  (ref) => LogTypeRepository(ref.watch(dioProvider)),
);

final userTypeRepositoryProvider = Provider<UserTypeRepository>(
  (ref) => UserTypeRepository(ref.watch(dioProvider)),
);

final versionRepositoryProvider = Provider<VersionRepository>(
  (ref) => VersionRepository(ref.watch(dioProvider)),
);
