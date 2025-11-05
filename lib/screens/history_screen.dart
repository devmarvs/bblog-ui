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
  const HistoryScreen({super.key});

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
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
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
      return Center(
        child: Text('No logs found for ${selectedSubUser.name}.'),
      );
    }
    final Map<DateTime, List<LogEntry>> groupedLogs = {};
    for (final log in _logs!) {
      final dayKey = DateTime(log.logTime.year, log.logTime.month, log.logTime.day);
      groupedLogs.putIfAbsent(dayKey, () => []).add(log);
    }
    final dates = groupedLogs.keys.toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log history for ${selectedSubUser.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final date in dates)
                  _buildLogColumn(
                    context,
                    date,
                    groupedLogs[date]!,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSubUsers(String userId) async {
    final previousSubUserId = _selectedSubUserId;
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
        defaultSelection = previousSubUserId != null
            ? data.firstWhere(
                (subUser) => subUser.subUserId == previousSubUserId,
                orElse: () => data.first,
              )
            : data.first;
      }
      setState(() {
        _subUsers = data;
        _selectedSubUserId = defaultSelection?.subUserId;
      });
      if (defaultSelection != null) {
        _loadLogsFor(defaultSelection);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _subUsersError = e.toString());
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
      final data = await repo.listBySubUser(userId, subUser.subUserId);
      if (!mounted) return;
      setState(() => _logs = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _logsError = e.toString());
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

  Widget _buildLogColumn(
    BuildContext context,
    DateTime date,
    List<LogEntry> logs,
  ) {
    final dayName = DateFormat('EEE').format(date);
    final dayNumber = DateFormat('d').format(date);
    final timeFormat = DateFormat.jm();
    final sortedLogs = List<LogEntry>.from(logs)
      ..sort((a, b) => a.logTime.compareTo(b.logTime));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = colorScheme.surfaceContainerHigh;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          Text(
            dayNumber,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < sortedLogs.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == sortedLogs.length - 1 ? 0 : 10),
              child: _LogEntryTile(
                title: sortedLogs[i].logName ??
                    'Log #${i + 1} (type ${sortedLogs[i].logTypeId})',
                description: sortedLogs[i].logDescription,
                timeLabel: timeFormat.format(sortedLogs[i].logTime),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({
    required this.title,
    this.description,
    required this.timeLabel,
  });

  final String title;
  final String? description;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
