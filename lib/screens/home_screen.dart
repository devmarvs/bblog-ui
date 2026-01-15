import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _HomeAction(
        title: 'Babies and Pets',
        subtitle: 'Manage caregivers, babies, or pets',
        icon: Icons.group_outlined,
        route: '/subusers',
      ),
      _HomeAction(
        title: 'Add Log',
        subtitle: 'Record a new activity in seconds',
        icon: Icons.add_circle_outline,
        route: '/add-log',
      ),
      _HomeAction(
        title: 'History',
        subtitle: 'Review logs by sub-user',
        icon: Icons.history,
        route: '/history',
      ),
      _HomeAction(
        title: 'Profile',
        subtitle: 'Adjust appearance and sign out',
        icon: Icons.person_outline,
        route: '/profile',
      ),
    ];

    void handleDestination(int index) {
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
    }

    Widget buildCards() {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _HomeActionCard(
            action: action,
            onTap: () => context.push(action.route),
          );
        },
        separatorBuilder: (_, unused) => const SizedBox(height: 12),
        itemCount: actions.length,
      );
    }

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (!isWide) {
          return buildCards();
        }
        return Row(
          children: [
            NavigationRail(
              selectedIndex: 0,
              onDestinationSelected: handleDestination,
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.group_outlined),
                  label: Text('Pets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('Add Log'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: buildCards()),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('Home'),
        actions: [
          OverflowMenuButton(
            actions: [
              OverflowAction(
                label: 'Profile',
                icon: Icons.person_outline,
                onPressed: () => context.push('/profile'),
              ),
              OverflowAction(
                label: 'Log out',
                icon: Icons.logout,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return const SizedBox.shrink();
          }
          return buildAppNavigationBar(context, currentIndex: 0);
        },
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({required this.action, required this.onTap});

  final _HomeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(action.title),
        subtitle: Text(action.subtitle),
        leading: CircleAvatar(
          child: Icon(action.icon),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
