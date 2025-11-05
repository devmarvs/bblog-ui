import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: const Text('Babies and Pets'),
                subtitle: const Text('Manage babies or pets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/subusers'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Add Log'),
                subtitle: const Text('Record a new activity'),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => context.push('/add-log'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('History'),
                subtitle: const Text('View logs by sub-user'),
                trailing: const Icon(Icons.history),
                onTap: () => context.push('/history'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.push('/subusers');
              break;
            case 2:
              context.push('/add-log');
              break;
            case 3:
              context.push('/history');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Pets/Babies',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Log',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
