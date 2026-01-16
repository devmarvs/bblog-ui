import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/error_message.dart';
import '../models/log_entry.dart';
import '../models/log_type.dart';
import '../models/sub_user.dart';
import '../models/user_type.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

enum _QuickTimeRange { now, minus1Hour, minus4Hours }

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
  List<UserType>? _userTypes;
  bool _loadingUserTypes = false;
  String? _userTypeError;
  _QuickTimeRange? _quickTimeRange = _QuickTimeRange.now;
  bool _authListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _logTime = _resolveQuickTime(_QuickTimeRange.now);
    _selectedLogType = _fallbackLogTypes.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadLogTypes();
      _loadUserTypes();
    });
  }

  @override
  void dispose() {
    _logDesc.dispose();
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
    }
    final authState = ref.watch(authControllerProvider);
    final userId = authState.userId ?? '';
    final hasUserId = userId.isNotEmpty;
    final canSubmit =
        !_submitting &&
        _selectedSubUser != null &&
        hasUserId &&
        _selectedLogType != null;
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
        leading: buildBackButton(context),
        title: const Text('Add Log'),
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
      body: RefreshIndicator.adaptive(
        onRefresh: () => _loadSubUsers(showSnackOnMissingId: false),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Babies and Pets',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              label: const Text('Add a baby or pet'),
              onPressed:
                  (!hasUserId ||
                      _loadingSubUsers ||
                      _submitting ||
                      _loadingUserTypes)
                  ? null
                  : _showCreateDialog,
            ),
            if (_userTypeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _userTypeError!,
                  style: const TextStyle(color: Colors.red),
                ),
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
                    DropdownMenu<int>(
                      initialSelection: _selectedLogType?.id,
                      dropdownMenuEntries: _logTypes
                          .map(
                            (option) => DropdownMenuEntry<int>(
                              value: option.id,
                              label: option.name,
                              labelWidget: _buildLogTypeLabel(context, option),
                            ),
                          )
                          .toList(),
                      label: const Text('Log type'),
                      onSelected: (value) {
                        if (value == null) return;
                        final match = _logTypes.firstWhere(
                          (element) => element.id == value,
                          orElse: () => _logTypes.first,
                        );
                        setState(() => _selectedLogType = match);
                      },
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<_QuickTimeRange>(
                      segments: const [
                        ButtonSegment(
                          value: _QuickTimeRange.now,
                          label: Text('Now'),
                          icon: Icon(Icons.flash_on_outlined),
                        ),
                        ButtonSegment(
                          value: _QuickTimeRange.minus1Hour,
                          label: Text('-1h'),
                          icon: Icon(Icons.timer_outlined),
                        ),
                        ButtonSegment(
                          value: _QuickTimeRange.minus4Hours,
                          label: Text('-4h'),
                          icon: Icon(Icons.schedule),
                        ),
                      ],
                      showSelectedIcon: false,
                      selected: _quickTimeRange == null
                          ? const <_QuickTimeRange>{}
                          : <_QuickTimeRange>{_quickTimeRange!},
                      onSelectionChanged: (values) {
                        if (values.isEmpty) {
                          setState(() => _quickTimeRange = null);
                          return;
                        }
                        final range = values.first;
                        setState(() {
                          _quickTimeRange = range;
                          _logTime = _resolveQuickTime(range);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Time: $formattedTime',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Pick time'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Add Activity Log',
                    loading: _submitting,
                    onPressed: canSubmit ? _submit : null,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: hasUserId
                          ? () => context.push('/history')
                          : null,
                      child: const Text('View history'),
                    ),
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
      bottomNavigationBar: buildAppNavigationBar(context, currentIndex: 2),
    );
  }

  Widget _buildSubUserList({required bool hasUserId}) {
    if (!hasUserId) {
      return const Text('Sign in to view your sub-users.');
    }
    if (_loadingSubUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator.adaptive()),
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
    final entries = _subUsers!
        .map(
          (sub) => DropdownMenuEntry<String>(
            value: sub.subUserId,
            label: sub.name,
            labelWidget: _buildSubUserLabel(sub),
          ),
        )
        .toList();
    return DropdownMenu<String>(
      initialSelection: _selectedSubUser?.subUserId,
      dropdownMenuEntries: entries,
      enableFilter: true,
      enableSearch: true,
      label: const Text('Select baby or pet'),
      onSelected: (value) {
        if (value == null) return;
        final selected = _subUsers!.firstWhere(
          (sub) => sub.subUserId == value,
          orElse: () => _subUsers!.first,
        );
        setState(() => _selectedSubUser = selected);
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
      _quickTimeRange = null;
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
        final friendly = friendlyErrorMessage(e);
        _logTypeError = 'Using default log types. $friendly';
        _logTypes = _fallbackLogTypes;
        _selectedLogType ??= _fallbackLogTypes.first;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingLogTypes = false);
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
        _subUserError = friendlyErrorMessage(e);
        _subUsers = null;
        _selectedSubUser = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSubUsers = false);
      }
    }
  }

  Widget _buildSubUserLabel(SubUserModel sub, {bool dense = false}) {
    final icon = _iconForSubUser(sub.userTypeId);
    final textStyle = dense
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Icon(icon, size: dense ? 20 : 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            sub.name,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  DateTime _resolveQuickTime(_QuickTimeRange range) {
    final now = DateTime.now();
    switch (range) {
      case _QuickTimeRange.now:
        return now;
      case _QuickTimeRange.minus1Hour:
        return now.subtract(const Duration(hours: 1));
      case _QuickTimeRange.minus4Hours:
        return now.subtract(const Duration(hours: 4));
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
    UserType? selectedType = _userTypes!.first;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sub-User'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserType>(
                  key: ValueKey(selectedType?.id),
                  initialValue: selectedType,
                  items: _userTypes!
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.description),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setStateDialog(() => selectedType = value),
                  decoration: const InputDecoration(labelText: 'Type'),
                  validator: (value) => value == null ? 'Select a type' : null,
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

    if (shouldCreate != true || selectedType == null) {
      nameCtrl.dispose();
      return;
    }

    final confirmedType = selectedType!;
    final repo = ref.read(subUserRepositoryProvider);
    try {
      final trimmedName = nameCtrl.text.trim();
      await repo.create(
        userId,
        name: trimmedName,
        userTypeId: confirmedType.id,
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
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      nameCtrl.dispose();
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
          content: Text(
            'Select a sub-user and log type before adding an activity log.',
          ),
        ),
      );
      return;
    }

    final numericSubUserId =
        subUser.subUserNumericId ?? int.tryParse(subUser.subUserId.trim());
    if (numericSubUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected baby or pet is missing a numeric id.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(logsRepositoryProvider);
    final entry = LogEntry(
      userLog: userId,
      subUserId: subUser.subUserId,
      subUserNumericId: numericSubUserId,
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
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildLogTypeLabel(BuildContext context, LogType type) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogTypeIcon(context, type),
        const SizedBox(width: 8),
        Flexible(child: Text(type.name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildLogTypeIcon(BuildContext context, LogType type) {
    final color = Theme.of(context).colorScheme.primary;
    final rule = _findLogIconRule(type);
    if (rule?.emoji != null) {
      return Text(rule!.emoji!, style: const TextStyle(fontSize: 20));
    }
    final icon = rule?.icon ?? Icons.event_note;
    return Icon(icon, color: color, size: 20);
  }
}

_LogIconRule? _findLogIconRule(LogType type) {
  final name = type.name.toLowerCase();
  for (final rule in _logIconRules) {
    if (rule.keywords.any(name.contains)) {
      return rule;
    }
  }
  return null;
}

class _LogIconRule {
  final List<String> keywords;
  final IconData? icon;
  final String? emoji;

  const _LogIconRule({required this.keywords, this.icon, this.emoji});
}

const List<_LogIconRule> _logIconRules = [
  // Diaper/Bathroom related
  _LogIconRule(
    keywords: ['poop', 'stool', 'bm', 'bowel', 'dirty'],
    emoji: '💩',
  ),
  _LogIconRule(
    keywords: ['pee', 'urine', 'wet', 'potty'],
    emoji: '💧',
  ),
  _LogIconRule(
    keywords: ['diaper', 'change', 'nappy', 'cloth'],
    emoji: '🧷',
  ),
  
  // Feeding related
  _LogIconRule(keywords: ['milk', 'bottle', 'formula'], emoji: '🍼'),
  _LogIconRule(
    keywords: ['feed', 'meal', 'food', 'eat', 'breakfast', 'lunch', 'dinner'],
    emoji: '🍽️',
  ),
  _LogIconRule(
    keywords: ['nurse', 'latch', 'breastfeed', 'nursing'],
    emoji: '🤱',
  ),
  _LogIconRule(keywords: ['pump', 'pumping'], emoji: '🍶'),
  _LogIconRule(keywords: ['snack', 'treat'], emoji: '🍪'),
  
  // Sleep related
  _LogIconRule(
    keywords: ['sleep', 'nap', 'bed', 'rest', 'doze', 'bedtime'],
    emoji: '😴',
  ),
  
  // Hygiene/Care
  _LogIconRule(
    keywords: ['bath', 'wash', 'shower', 'tub', 'clean'],
    emoji: '🛁',
  ),
  _LogIconRule(keywords: ['teeth', 'brush', 'dental'], emoji: '🪥'),
  _LogIconRule(keywords: ['groom', 'haircut', 'trim', 'clip'], emoji: '✂️'),
  
  // Health/Medical
  _LogIconRule(
    keywords: ['med', 'medicine', 'medication', 'drug', 'dose', 'vitamin'],
    emoji: '💊',
  ),
  _LogIconRule(
    keywords: ['doctor', 'clinic', 'checkup', 'health', 'nurse', 'visit'],
    emoji: '🏥',
  ),
  _LogIconRule(
    keywords: ['temperature', 'temp', 'fever', 'thermometer'],
    emoji: '🌡️',
  ),
  _LogIconRule(
    keywords: ['vaccine', 'vaccination', 'shot', 'immunization'],
    emoji: '💉',
  ),
  _LogIconRule(keywords: ['sick', 'ill', 'unwell'], emoji: '🤒'),
  _LogIconRule(keywords: ['weight', 'weigh', 'scale'], emoji: '⚖️'),
  
  // Activity/Play
  _LogIconRule(
    keywords: ['walk', 'exercise', 'run', 'outside', 'stroll'],
    emoji: '🚶',
  ),
  _LogIconRule(keywords: ['play', 'toy', 'lego', 'game'], emoji: '🧸'),
  _LogIconRule(keywords: ['park', 'playground', 'swing'], emoji: '🎠'),
  _LogIconRule(keywords: ['tummy', 'tummy time'], emoji: '🤸'),
  
  // Learning/Development
  _LogIconRule(keywords: ['story', 'read', 'book'], emoji: '📚'),
  _LogIconRule(keywords: ['music', 'song', 'sing'], emoji: '🎵'),
  _LogIconRule(keywords: ['train', 'practice', 'learn'], emoji: '🎓'),
  _LogIconRule(keywords: ['milestone', 'achievement'], emoji: '🏆'),
  
  // Emotions/Behavior
  _LogIconRule(keywords: ['cry', 'crying', 'fussy', 'upset'], emoji: '😢'),
  _LogIconRule(keywords: ['happy', 'smile', 'laugh'], emoji: '😊'),
  _LogIconRule(keywords: ['calm', 'peaceful', 'quiet'], emoji: '😌'),
  
  // Special moments
  _LogIconRule(keywords: ['photo', 'picture', 'camera'], emoji: '📸'),
  _LogIconRule(keywords: ['birth', 'birthday', 'party'], emoji: '🎂'),
  _LogIconRule(keywords: ['gift', 'present'], emoji: '🎁'),
  
  // Default/General
  _LogIconRule(
    keywords: ['note', 'journal', 'general', 'other', 'misc'],
    emoji: '📝',
  ),
];
