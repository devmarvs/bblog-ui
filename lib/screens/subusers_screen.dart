import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/error_message.dart';
import '../models/sub_user.dart';
import '../models/user_type.dart';
import '../providers/repository_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/common.dart';

class SubUsersScreen extends ConsumerStatefulWidget {
  const SubUsersScreen({super.key});

  @override
  ConsumerState<SubUsersScreen> createState() => _SubUsersScreenState();
}

class _SubUsersScreenState extends ConsumerState<SubUsersScreen> {
  List<SubUserModel>? _items;
  bool _loading = false;
  String? _error;
  List<UserType>? _userTypes;
  bool _loadingUserTypes = false;
  String? _userTypeError;
  final SearchController _searchController = SearchController();
  int? _selectedUserTypeId;
  bool _authListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserTypes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authListenerAttached) {
      _authListenerAttached = true;
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
    }

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
        leading: buildBackButton(context),
        title: const Text('Babies and Pets'),
        actions: [
          OverflowMenuButton(
            actions: [
              OverflowAction(
                label: 'Home',
                icon: Icons.home_outlined,
                onPressed: () => context.go('/home'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your babies and pets',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Badge.count(
                  count: _filteredSubUsers.length,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  child: const Icon(Icons.pets_outlined),
                ),
                const SizedBox(width: 8),
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
              onPressed: (_loading || !hasUser || _loadingUserTypes)
                  ? null
                  : _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add a baby or pet'),
            ),
            if (_userTypeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _userTypeError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (hasUser) ...[
              _buildFilters(),
              const SizedBox(height: 12),
            ],
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: buildAppNavigationBar(context, currentIndex: 1),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchAnchor.bar(
          searchController: _searchController,
          barHintText: 'Search babies or pets',
          viewHintText: 'Search by name or description',
          suggestionsBuilder: _buildSearchSuggestions,
        ),
        const SizedBox(height: 12),
        DropdownMenu<int?>(
          initialSelection: _selectedUserTypeId,
          dropdownMenuEntries: [
            const DropdownMenuEntry<int?>(
              value: null,
              label: 'All categories',
            ),
            if (_userTypes != null)
              ..._userTypes!.map(
                (type) => DropdownMenuEntry<int?>(
                  value: type.id,
                  label: type.description,
                ),
              ),
          ],
          leadingIcon: const Icon(Icons.category_outlined),
          label: const Text('Filter by category'),
          helperText: _userTypes == null
              ? 'Categories load automatically after syncing.'
              : null,
          onSelected: (value) {
            setState(() => _selectedUserTypeId = value);
          },
          enabled: !_loadingUserTypes && (_userTypes?.isNotEmpty ?? false),
        ),
      ],
    );
  }

  Iterable<Widget> _buildSearchSuggestions(
    BuildContext context,
    SearchController controller,
  ) {
    final query = controller.text.trim().toLowerCase();
    final items = _items ?? const <SubUserModel>[];
    if (items.isEmpty) {
      return const [
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('No entries yet'),
          subtitle: Text('Add a baby or pet to start searching.'),
        ),
      ];
    }
    final matches = items.where((item) {
      if (query.isEmpty) return true;
      final normalized = item.name.toLowerCase();
      final desc = item.description?.toLowerCase() ?? '';
      return normalized.contains(query) || desc.contains(query);
    }).take(6).toList();
    if (matches.isEmpty) {
      return const [
        ListTile(
          leading: Icon(Icons.search_off),
          title: Text('No matches'),
          subtitle: Text('Try a different search term.'),
        ),
      ];
    }
    return matches.map(
      (item) => ListTile(
        leading: Icon(_iconForSubUser(item.userTypeId)),
        title: Text(item.name),
        subtitle: item.description == null ? null : Text(item.description!),
        onTap: () {
          controller.closeView(item.name);
          controller.text = item.name;
          _handleSearchChanged();
        },
        trailing: IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'View history',
          onPressed: () {
            final destination =
                '/history?subUserId=${Uri.encodeComponent(item.subUserId)}';
            context.push(destination);
          },
        ),
      ),
    );
  }

  List<SubUserModel> get _filteredSubUsers {
    final items = _items;
    if (items == null) return const [];
    final query = _searchController.text.trim().toLowerCase();
    final typeFilter = _selectedUserTypeId;
    return items.where((item) {
      final matchesType =
          typeFilter == null || item.userTypeId == typeFilter;
      final normalized = item.name.toLowerCase();
      final description = item.description?.toLowerCase() ?? '';
      final matchesQuery =
          query.isEmpty || normalized.contains(query) || description.contains(query);
      return matchesType && matchesQuery;
    }).toList();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildBody() {
    final hasUser = (ref.read(authControllerProvider).userId ?? '').isNotEmpty;
    if (!hasUser) {
      return const Center(child: Text('Sign in to view your sub-users.'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (_items == null) {
      return const Center(child: Text('Fetching sub-users...'));
    }
    if (_items!.isEmpty) {
      return const Center(child: Text('No sub-users yet'));
    }
    final visibleItems = _filteredSubUsers;
    if (visibleItems.isEmpty) {
      return const Center(
        child: Text('No sub-users match the current filters.'),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () => _load(showSnackOnMissingId: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleItems.length,
        separatorBuilder: (_, index) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = visibleItems[index];
          final iconData = _iconForSubUser(item.userTypeId);
          return ListTile(
            leading: Icon(iconData),
            title: Text(item.name),
            subtitle: (item.description != null &&
                    item.description!.isNotEmpty)
                ? Text(item.description!)
                : null,
            trailing: const Icon(Icons.history),
            onTap: () {
              final destination =
                  '/history?subUserId=${Uri.encodeComponent(item.subUserId)}';
              context.push(destination);
            },
          );
        },
      ),
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
      setState(() => _error = friendlyErrorMessage(e));
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

    if ((_userTypes == null || _userTypes!.isEmpty) && !_loadingUserTypes) {
      await _loadUserTypes();
    }
    if (!mounted) return;

    if (_userTypes == null || _userTypes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load sub-user types. Try again later.'),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final availableTypes = _userTypes!
        .where((type) => type.description.trim().toLowerCase() != 'user')
        .toList();

    if (availableTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sub-user types available at the moment.'),
        ),
      );
      return;
    }

    UserType? selectedType = availableTypes.first;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Baby or Pet'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownMenu<UserType>(
                  initialSelection: selectedType,
                  dropdownMenuEntries: availableTypes
                      .map(
                        (type) => DropdownMenuEntry<UserType>(
                          value: type,
                          label: type.description,
                        ),
                      )
                      .toList(),
                  label: const Text('Type'),
                  onSelected: (value) {
                    setStateDialog(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a name'
                      : null,
                ),
              ],
            ),
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
          userTypeId: selectedType!.id,
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
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }

  }

  Future<void> _loadUserTypes() async {
    setState(() {
      _loadingUserTypes = true;
      _userTypeError = null;
    });

    final repo = ref.read(userTypeRepositoryProvider);
    try {
      final types = await repo.list();
      if (!mounted) return;
      setState(() {
        _userTypes = types;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userTypes = null;
        _userTypeError = friendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loadingUserTypes = false);
      }
    }
  }

  IconData _iconForSubUser(int? userTypeId) {
    switch (userTypeId) {
      case 2:
        return Icons.child_friendly;
      case 3:
        return Icons.pets;
      default:
        return Icons.person_outline;
    }
  }
}
