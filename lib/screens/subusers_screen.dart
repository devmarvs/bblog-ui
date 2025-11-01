import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/sub_user.dart';
import '../providers/repository_providers.dart';
import '../providers/auth_providers.dart';

class SubUsersScreen extends ConsumerStatefulWidget {
  const SubUsersScreen({super.key});

  @override
  ConsumerState<SubUsersScreen> createState() => _SubUsersScreenState();
}

class _SubUsersScreenState extends ConsumerState<SubUsersScreen> {
  List<SubUserModel>? _items;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final prevId = previous?.userId ?? '';
      final nextId = next.userId ?? '';
      if (nextId.isNotEmpty && nextId != prevId) {
        _load(userId: nextId, showSnackOnMissingId: false);
      }
      if (nextId.isEmpty && prevId.isNotEmpty) {
        setState(() {
          _items = null;
          _error = null;
          _loading = false;
        });
      }
    });

    final authState = ref.watch(authControllerProvider);
    final userId = authState.userId ?? '';
    final hasUser = userId.isNotEmpty;

    if (hasUser && !_loading && _items == null && _error == null) {
      Future.microtask(
        () => _load(userId: userId, showSnackOnMissingId: false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Babies and Pets'),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: (_loading || !hasUser)
                      ? null
                      : () => _load(showSnackOnMissingId: false),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (_loading || !hasUser) ? null : _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Sub-User'),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final hasUser = (ref.read(authControllerProvider).userId ?? '').isNotEmpty;
    if (!hasUser) {
      return const Center(child: Text('Sign in to view your sub-users.'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_items == null) {
      return const Center(child: Text('Fetching sub-users...'));
    }
    if (_items!.isEmpty) {
      return const Center(child: Text('No sub-users yet'));
    }
    return ListView.separated(
      itemCount: _items!.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = _items![index];
        return ListTile(
          leading: const Icon(Icons.child_care),
          title: Text(item.name),
          subtitle: Text(item.description ?? 'No description'),
        );
      },
    );
  }

  Future<void> _load({String? userId, bool showSnackOnMissingId = true}) async {
    final id = userId ?? ref.read(authControllerProvider).userId ?? '';
    if (id.isEmpty) {
      if (showSnackOnMissingId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User information unavailable.')),
        );
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(subUserRepositoryProvider);
    try {
      final data = await repo.list(id);
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final userId = ref.read(authControllerProvider).userId ?? '';
    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add sub-user without a valid account.'),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sub-User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (shouldCreate == true) {
      final repo = ref.read(subUserRepositoryProvider);
      try {
        await repo.create(
          userId,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sub-user created')));
        await _load(showSnackOnMissingId: false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    nameCtrl.dispose();
    descCtrl.dispose();
  }
}
