import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              value: isDarkMode,
              onChanged: (value) =>
                  ref.read(themeModeProvider.notifier).setDarkMode(value),
            ),
            const SizedBox(height: 24),
            const Text('Signed in'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
