import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';
import '../models/log_type.dart';
import '../models/sub_user.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _logDesc = TextEditingController();

  static const List<LogType> _fallbackLogTypes = [
    LogType(id: 1, name: 'Feeding'),
    LogType(id: 2, name: 'Diaper Change'),
    LogType(id: 3, name: 'Sleep'),
    LogType(id: 4, name: 'Bath'),
    LogType(id: 5, name: 'Medication'),
  ];

  List<LogType> _logTypes = _fallbackLogTypes;
  LogType? _selectedLogType;
  bool _loadingLogTypes = false;
  String? _logTypeError;
  List<SubUserModel>? _subUsers;
  SubUserModel? _selectedSubUser;
  bool _loadingSubUsers = false;
  String? _subUserError;
  DateTime _logTime = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLogType = _fallbackLogTypes.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadLogTypes();
    });
  }

  @override
  void dispose() {
    _logDesc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final prevId = previous?.userId ?? '';
      final nextId = next.userId ?? '';
      if (nextId.isNotEmpty && nextId != prevId) {
        _loadSubUsers(userId: nextId, showSnackOnMissingId: false);
      }
      if (nextId.isEmpty && prevId.isNotEmpty) {
        setState(() {
          _subUsers = null;
          _selectedSubUser = null;
          _subUserError = null;
        });
      }
    });
    final authState = ref.watch(authControllerProvider);
    final userId = authState.userId ?? '';
    final hasUserId = userId.isNotEmpty;
    final canSubmit =
        !_submitting && _selectedSubUser != null && hasUserId && _selectedLogType != null;
    final formattedTime = DateFormat.yMd().add_jm().format(_logTime);

    if (hasUserId &&
        !_loadingSubUsers &&
        _subUsers == null &&
        _subUserError == null) {
      Future.microtask(
        () => _loadSubUsers(userId: userId, showSnackOnMissingId: false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Log'),
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
      body: RefreshIndicator(
        onRefresh: () => _loadSubUsers(showSnackOnMissingId: false),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sub-Users',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loadingSubUsers
                      ? null
                      : () => _loadSubUsers(showSnackOnMissingId: false),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Sub-User'),
              onPressed: (!hasUserId || _loadingSubUsers || _submitting)
                  ? null
                  : _showCreateDialog,
            ),
            const SizedBox(height: 16),
            _buildSubUserList(hasUserId: hasUserId),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingLogTypes)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    )
                  else
                    DropdownButtonFormField<LogType>(
                      key: ValueKey(_selectedLogType?.id),
                      initialValue: _selectedLogType,
                      items: _logTypes
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option.name),
                            ),
                          )
                          .toList(),
                      onChanged: (option) {
                        if (option == null) return;
                        setState(() => _selectedLogType = option);
                      },
                      decoration: const InputDecoration(labelText: 'Log type'),
                    ),
                  if (_logTypeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _logTypeError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _logDesc,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('Time: $formattedTime')),
                      TextButton(
                        onPressed: _pickDateTime,
                        child: const Text('Pick time'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Add Activity Log',
                    loading: _submitting,
                    onPressed: canSubmit ? _submit : null,
                  ),
                  if (_selectedSubUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Logging for ${_selectedSubUser!.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (!hasUserId)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'User details unavailable. Please log in again.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubUserList({required bool hasUserId}) {
    if (!hasUserId) {
      return const Text('Sign in to view your sub-users.');
    }
    if (_loadingSubUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_subUserError != null) {
      return Text(_subUserError!, style: const TextStyle(color: Colors.red));
    }
    if (_subUsers == null) {
      return const Text('Fetching sub-users...');
    }
    if (_subUsers!.isEmpty) {
      return const Text('No sub-users yet. Add one to start logging.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subUsers!.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final sub = _subUsers![index];
        final isSelected = _selectedSubUser?.subUserId == sub.subUserId;
        return Card(
          elevation: isSelected ? 2 : 0,
          child: ListTile(
            title: Text(sub.name),
            subtitle: (sub.description != null && sub.description!.isNotEmpty)
                ? Text(sub.description!)
                : null,
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedSubUser = sub;
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _logTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_logTime),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _logTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _loadLogTypes() async {
    setState(() {
      _loadingLogTypes = true;
      _logTypeError = null;
    });

    final repo = ref.read(logTypeRepositoryProvider);
    try {
      final types = await repo.list();
      if (!mounted) return;
      setState(() {
        if (types.isNotEmpty) {
          _logTypes = types;
          _selectedLogType = _selectedLogType != null
              ? types.firstWhere(
                  (t) => t.id == _selectedLogType!.id,
                  orElse: () => types.first,
                )
              : types.first;
        } else {
          _logTypes = _fallbackLogTypes;
          _selectedLogType = _fallbackLogTypes.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logTypeError = 'Using default log types. Error: $e';
        _logTypes = _fallbackLogTypes;
        _selectedLogType ??= _fallbackLogTypes.first;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingLogTypes = false);
      }
    }
  }

  Future<void> _loadSubUsers({
    String? userId,
    bool showSnackOnMissingId = true,
  }) async {
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
      _loadingSubUsers = true;
      _subUserError = null;
    });

    final repo = ref.read(subUserRepositoryProvider);
    try {
      final data = await repo.list(id);
      if (!mounted) return;
      setState(() {
        _subUsers = data;
        final currentId = _selectedSubUser?.subUserId;
        SubUserModel? selection;
        if (currentId != null) {
          for (final item in data) {
            if (item.subUserId == currentId) {
              selection = item;
              break;
            }
          }
        }
        _selectedSubUser = selection ?? (data.isNotEmpty ? data.first : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subUserError = e.toString();
        _subUsers = null;
        _selectedSubUser = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSubUsers = false);
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
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a name'
                    : null,
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

    if (shouldCreate != true) return;

    final repo = ref.read(subUserRepositoryProvider);
    try {
      final trimmedName = nameCtrl.text.trim();
      final trimmedDesc = descCtrl.text.trim();
      await repo.create(
        userId,
        name: trimmedName,
        description: trimmedDesc.isEmpty ? null : trimmedDesc,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sub-user $trimmedName created')));
      await _loadSubUsers(showSnackOnMissingId: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submit() async {
    final userId = ref.read(authControllerProvider).userId ?? '';
    final subUser = _selectedSubUser;
    final logType = _selectedLogType;
    if (userId.isEmpty || subUser == null || logType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a sub-user and log type before adding an activity log.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(logsRepositoryProvider);
    final entry = LogEntry(
      userLog: userId,
      subUserId: subUser.subUserId,
      logTypeId: logType.id,
      logName: logType.name,
      logTime: _logTime,
      logDescription: _logDesc.text.trim().isEmpty
          ? null
          : _logDesc.text.trim(),
    );

    try {
      await repo.createLog(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log created for ${subUser.name}')),
      );
      _logDesc.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
