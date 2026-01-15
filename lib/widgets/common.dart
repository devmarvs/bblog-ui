import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'glass.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  const Section({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

Widget? buildBackButton(BuildContext context) {
  final router = GoRouter.of(context);
  if (!router.canPop()) return null;
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: 'Back',
    onPressed: () => router.pop(),
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlight = colors.secondary;
    final primary = colors.primary;
    final surface = colors.surface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, highlight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.child_care, color: surface, size: size * 0.35),
                Icon(Icons.pets, color: surface, size: size * 0.35),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Baby and Pet Log',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Gentle care for little ones and furry friends',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class OverflowAction {
  const OverflowAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool destructive;
  final bool enabled;
}

class OverflowMenuButton extends StatelessWidget {
  const OverflowMenuButton({
    super.key,
    required this.actions,
    this.tooltip = 'More actions',
    this.icon = Icons.more_vert,
  });

  final List<OverflowAction> actions;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final available = actions.where((action) => action.enabled).toList();
    if (available.isEmpty) {
      return const SizedBox.shrink();
    }
    return MenuAnchor(
      menuChildren: [
        for (final action in available)
          MenuItemButton(
            leadingIcon: action.icon == null ? null : Icon(action.icon),
            style: action.destructive
                ? MenuItemButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: action.onPressed,
            child: Text(action.label),
          ),
      ],
      builder: (context, controller, _) {
        return IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
        );
      },
    );
  }
}

NavigationBar buildAppNavigationBar(
  BuildContext context, {
  required int currentIndex,
}) {
  void handleSelection(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/subusers');
        break;
      case 2:
        context.go('/add-log');
        break;
      case 3:
        context.go('/history');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  return NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: handleSelection,
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
  );
}
