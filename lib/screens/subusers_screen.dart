import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sub_user.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

class SubUsersScreen extends ConsumerStatefulWidget {
  const SubUsersScreen({super.key});

  @override
  ConsumerState<SubUsersScreen> createState() => _SubUsersScreenState();
}

class _SubUsersScreenState extends ConsumerState<SubUsersScreen> {
  final _userIdCtrl = TextEditingController();

  List<SubUserModel>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userIdCtrl.addListener(_onUserIdChanged);
  }

  @override
  void dispose() {
    _userIdCtrl.removeListener(_onUserIdChanged);
    _userIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sub-Users')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdCtrl,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Load',
                    loading: _loading,
                    onPressed: _loading ? null : _load,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: (_loading || _userIdCtrl.text.trim().isEmpty)
                      ? null
                      : () => _showCreateDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  void _onUserIdChanged() => setState(() {});

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_items == null) {
      return const Center(child: Text('Enter a user ID to load sub-users'));
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

  Future<void> _load() async {
    final userId = _userIdCtrl.text.trim();
    if (userId.isEmpty) {
      setState(() => _error = 'Enter a user ID first');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(subUserRepositoryProvider);
    try {
      final data = await repo.list(userId);
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
          _userIdCtrl.text.trim(),
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sub-user created')));
        await _load();
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
