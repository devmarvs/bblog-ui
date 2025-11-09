import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';
import '../models/sub_user.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.initialSubUserId});

  final String? initialSubUserId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _loadingLogs = false;
  bool _loadingSubUsers = false;
  String? _logsError;
  String? _subUsersError;
  List<LogEntry>? _logs;
  List<SubUserModel>? _subUsers;
  String? _selectedSubUserId;
  String? _lastRequestedUserId;
  String? _initialSubUserId;

  @override
  void initState() {
    super.initState();
    _initialSubUserId = widget.initialSubUserId;
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubUserId != oldWidget.initialSubUserId) {
      _initialSubUserId = widget.initialSubUserId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final userId = authState.userId;

    if (userId == null && _lastRequestedUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _lastRequestedUserId = null;
          _subUsers = null;
          _selectedSubUserId = null;
          _logs = null;
          _subUsersError = null;
          _logsError = null;
          _initialSubUserId = widget.initialSubUserId;
        });
      });
    } else if (userId != null && userId != _lastRequestedUserId) {
      _lastRequestedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSubUsers(userId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('History'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubUserList(userId),
            const SizedBox(height: 12),
            Expanded(child: _buildLogList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSubUserList(String? userId) {
    if (_loadingSubUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (userId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Sign in to view sub-users.')),
      );
    }
    if (_subUsersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _subUsersError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Retry',
              onPressed: () => _loadSubUsers(userId),
            ),
          ],
        ),
      );
    }
    if (_subUsers == null) {
      return const SizedBox.shrink();
    }
    if (_subUsers!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No sub-users found.')),
      );
    }
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Select sub-user',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedSubUserId,
          hint: const Text('Choose a sub-user'),
          items: _subUsers!
              .map(
                (subUser) => DropdownMenuItem<String>(
                  value: subUser.subUserId,
                  child: SizedBox(
                    height: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subUser.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (subUser.description != null)
                          Text(
                            subUser.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            final selected = _findSubUserById(value);
            if (selected != null) {
              _loadLogsFor(selected);
            }
          },
          selectedItemBuilder: (context) => _subUsers!
              .map(
                (subUser) => SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subUser.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLogList() {
    final selectedSubUser = _findSubUserById(_selectedSubUserId);
    if (selectedSubUser == null) {
      return const Center(child: Text('Select a sub-user to view logs.'));
    }
    if (_loadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logsError != null) {
      return Center(
        child: Text(
          _logsError!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_logs == null) {
      return const SizedBox.shrink();
    }
    if (_logs!.isEmpty) {
      return Center(child: Text('No logs found for ${selectedSubUser.name}.'));
    }
    final sortedLogs = List<LogEntry>.from(_logs!)
      ..sort(
        // Most recent logs first for easier scanning in a vertical list.
        (a, b) => b.logTime.compareTo(a.logTime),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log history for ${selectedSubUser.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemBuilder: (context, index) =>
                _HistoryLogCard(log: sortedLogs[index]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: sortedLogs.length,
          ),
        ),
      ],
    );
  }

  Future<void> _loadSubUsers(String userId) async {
    final previousSubUserId = _selectedSubUserId;
    final pendingInitialSelection = _initialSubUserId;
    setState(() {
      _loadingSubUsers = true;
      _subUsersError = null;
      _subUsers = null;
      _selectedSubUserId = null;
      _logs = null;
      _logsError = null;
    });
    final repo = ref.read(subUserRepositoryProvider);
    try {
      final data = await repo.list(userId);
      if (!mounted) return;
      SubUserModel? defaultSelection;
      if (data.isNotEmpty) {
        final desiredId = previousSubUserId ?? pendingInitialSelection;
        if (desiredId != null) {
          defaultSelection = data.firstWhere(
            (subUser) => subUser.subUserId == desiredId,
            orElse: () => data.first,
          );
        } else {
          defaultSelection = data.first;
        }
      }
      setState(() {
        _subUsers = data;
        _selectedSubUserId = defaultSelection?.subUserId;
        if (_selectedSubUserId == pendingInitialSelection) {
          _initialSubUserId = null;
        }
      });
      if (defaultSelection != null) {
        _loadLogsFor(defaultSelection);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subUsersError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSubUsers = false);
      }
    }
  }

  Future<void> _loadLogsFor(SubUserModel subUser) async {
    final authState = ref.read(authControllerProvider);
    final userId = authState.userId;
    if (userId == null) {
      setState(() {
        _selectedSubUserId = subUser.subUserId;
        _logsError = 'Unable to determine user ID.';
        _logs = null;
      });
      return;
    }
    setState(() {
      _selectedSubUserId = subUser.subUserId;
      _loadingLogs = true;
      _logsError = null;
      _logs = null;
    });
    final repo = ref.read(logsRepositoryProvider);
    try {
      final result = await repo.listBySubUser(userId, subUser.subUserId);
      if (!mounted) return;
      setState(() {
        _logs = result.entries;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingLogs = false);
      }
    }
  }

  SubUserModel? _findSubUserById(String? id) {
    if (id == null) return null;
    final subUsers = _subUsers;
    if (subUsers == null) return null;
    for (final subUser in subUsers) {
      if (subUser.subUserId == id) {
        return subUser;
      }
    }
    return null;
  }
}

class _HistoryLogCard extends StatelessWidget {
  const _HistoryLogCard({required this.log});

  final LogEntry log;

  static final DateFormat _timeFormat = DateFormat.yMMMEd()
      .add_jm(); // e.g. Jan 2, 2024 8:30 PM

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadata = _metadataForLog(log);
    final description = log.logDescription?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                child: metadata.emoji != null
                    ? Text(
                        metadata.emoji!,
                        style: TextStyle(
                          fontSize: 24,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(metadata.icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log type',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      metadata.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LogDetailRow(
            label: 'Log time',
            value: _timeFormat.format(log.logTime),
          ),
          const SizedBox(height: 12),
          _LogDetailRow(
            label: 'Log description',
            value: hasDescription ? description! : 'No description provided',
            muted: !hasDescription,
          ),
        ],
      ),
    );
  }

  static _LogTypeMetadata _metadataForLog(LogEntry log) {
    final label = _resolveLogLabel(log);
    final normalized = label.toLowerCase();
    final keywordMatch = _metadataFromKeywords(label, normalized);
    if (keywordMatch != null) {
      return keywordMatch;
    }
    switch (log.logTypeId) {
      case 1:
        return _LogTypeMetadata(label: label, icon: Icons.local_drink);
      case 2:
        return _LogTypeMetadata(
          label: label,
          icon: Icons.baby_changing_station,
        );
      case 3:
        return _LogTypeMetadata(label: label, icon: Icons.bedtime);
      case 4:
        return _LogTypeMetadata(label: label, icon: Icons.shower);
      case 5:
        return _LogTypeMetadata(label: label, icon: Icons.medical_services);
      default:
        return _LogTypeMetadata(label: label, icon: Icons.event_note);
    }
  }

  static String _resolveLogLabel(LogEntry log) {
    final custom = log.logName?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return _defaultLogTypeNames[log.logTypeId] ?? 'Log Type ${log.logTypeId}';
  }

  static _LogTypeMetadata? _metadataFromKeywords(
    String label,
    String normalized,
  ) {
    if (_matches(normalized, const ['poop', 'poo', 'bm', 'bowel', 'stool'])) {
      return _LogTypeMetadata(label: label, emoji: '💩');
    }
    if (_matches(normalized, const ['pee', 'urine', 'wet'])) {
      return _LogTypeMetadata(label: label, icon: Icons.water_drop);
    }
    if (_matches(normalized, const ['diaper', 'nappy', 'change'])) {
      return _LogTypeMetadata(label: label, icon: Icons.baby_changing_station);
    }
    if (_matches(normalized, const ['milk', 'feed', 'bottle', 'nurse'])) {
      return _LogTypeMetadata(label: label, icon: Icons.local_drink);
    }
    if (_matches(normalized, const ['sleep', 'nap', 'rest'])) {
      return _LogTypeMetadata(label: label, icon: Icons.bedtime);
    }
    if (_matches(normalized, const ['bath', 'shower', 'wash'])) {
      return _LogTypeMetadata(label: label, icon: Icons.shower);
    }
    if (_matches(normalized, const ['med', 'medicine', 'vitamin'])) {
      return _LogTypeMetadata(label: label, icon: Icons.medical_services);
    }
    return null;
  }

  static bool _matches(String normalized, List<String> keywords) {
    return keywords.any((keyword) => normalized.contains(keyword));
  }
}

class _LogTypeMetadata {
  const _LogTypeMetadata({required this.label, this.icon, this.emoji})
    : assert(icon != null || emoji != null);

  final String label;
  final IconData? icon;
  final String? emoji;
}

class _LogDetailRow extends StatelessWidget {
  const _LogDetailRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted ? colorScheme.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }
}

const Map<int, String> _defaultLogTypeNames = {
  1: 'Feeding',
  2: 'Diaper Change',
  3: 'Sleep',
  4: 'Bath',
  5: 'Medication',
};
