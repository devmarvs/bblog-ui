import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/version_info.dart';
import 'repository_providers.dart';

final versionInfoProvider = FutureProvider<VersionInfo?>((ref) async {
  final repo = ref.watch(versionRepositoryProvider);
  return repo.fetch();
});
