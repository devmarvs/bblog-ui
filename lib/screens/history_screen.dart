import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/error_message.dart';
import '../models/log_entry.dart';
import '../models/sub_user.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

enum HistoryRange { day, week, month, all }

const List<ButtonSegment<HistoryRange>> _historyRangeSegments = [
  ButtonSegment<HistoryRange>(
    value: HistoryRange.day,
    icon: Icon(Icons.wb_sunny_outlined),
    label: Text('24h'),
  ),
  ButtonSegment<HistoryRange>(
    value: HistoryRange.week,
    icon: Icon(Icons.calendar_view_week),
    label: Text('7d'),
  ),
  ButtonSegment<HistoryRange>(
    value: HistoryRange.month,
    icon: Icon(Icons.calendar_view_month),
    label: Text('30d'),
  ),
  ButtonSegment<HistoryRange>(
    value: HistoryRange.all,
    icon: Icon(Icons.all_inclusive),
    label: Text('All'),
  ),
];

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
  final TextEditingController _subUserFieldController = TextEditingController();
  final SearchController _searchController = SearchController();
  final ScrollController _logScrollController = ScrollController();
  HistoryRange _range = HistoryRange.week;

  @override
  void initState() {
    super.initState();
    _initialSubUserId = widget.initialSubUserId;
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubUserId != oldWidget.initialSubUserId) {
      _initialSubUserId = widget.initialSubUserId;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _subUserFieldController.dispose();
    _logScrollController.dispose();
    super.dispose();
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

    final filterControls = _buildFilterControls();

    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('History'),
        actions: [
          OverflowMenuButton(
            tooltip: 'Quick actions',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubUserList(userId),
            const SizedBox(height: 12),
            if (filterControls != null) ...[
              filterControls,
              const SizedBox(height: 12),
            ],
            Expanded(child: _buildLogList()),
          ],
        ),
      ),
      bottomNavigationBar: buildAppNavigationBar(context, currentIndex: 3),
    );
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildSubUserList(String? userId) {
    if (_loadingSubUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
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
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final entries = _subUsers!
        .map(
          (subUser) => DropdownMenuEntry<String>(
            value: subUser.subUserId,
            label: subUser.name,
            labelWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subUser.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if ((subUser.description ?? '').trim().isNotEmpty)
                  Text(
                    subUser.description!.trim(),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: onSurfaceVariant),
                  ),
              ],
            ),
            leadingIcon: Icon(_iconForSubUser(subUser.userTypeId)),
          ),
        )
        .toList();
    return DropdownMenu<String>(
      controller: _subUserFieldController,
      initialSelection: _selectedSubUserId,
      requestFocusOnTap: false,
      enabled: !_loadingLogs,
      enableFilter: true,
      enableSearch: true,
      label: const Text('Select sub-user'),
      dropdownMenuEntries: entries,
      onSelected: (value) {
        if (value == null) return;
        final selected = _findSubUserById(value);
        if (selected != null) {
          _applySubUserSelection(selected);
        }
      },
    );
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

  void _applySubUserSelection(SubUserModel subUser, {bool loadLogs = true}) {
    if (!mounted) return;
    setState(() {
      _selectedSubUserId = subUser.subUserId;
      _subUserFieldController.text = subUser.name;
    });
    if (loadLogs) {
      _loadLogsFor(subUser);
    }
  }

  Widget? _buildFilterControls() {
    if (_selectedSubUserId == null || (_subUsers?.isEmpty ?? true)) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchAnchor.bar(
          searchController: _searchController,
          barHintText: 'Search logs by name, note, or type',
          viewHintText: 'Search logs',
          suggestionsBuilder: _buildSearchSuggestions,
        ),
        const SizedBox(height: 12),
        SegmentedButton<HistoryRange>(
          showSelectedIcon: false,
          segments: _historyRangeSegments,
          selected: <HistoryRange>{_range},
          onSelectionChanged: (values) {
            if (values.isEmpty) return;
            setState(() => _range = values.first);
          },
        ),
      ],
    );
  }

  Iterable<Widget> _buildSearchSuggestions(
    BuildContext context,
    SearchController controller,
  ) {
    final query = controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return const Iterable<Widget>.empty();
    }
    final matches = (_logs ?? const <LogEntry>[])
        .where((log) => _logMatchesQuery(log, query))
        .take(6)
        .toList();
    if (matches.isEmpty) {
      return const [
        ListTile(
          leading: Icon(Icons.search_off),
          title: Text('No matching logs'),
          subtitle: Text('Try adjusting your search terms.'),
        ),
      ];
    }
    final formatter = DateFormat('MMM d • h:mm a');
    return matches.map(
      (log) => ListTile(
        leading: const Icon(Icons.history),
        title: Text(_HistoryLogCard._resolveLogLabel(log)),
        subtitle: Text(formatter.format(log.logTime)),
        onTap: () {
          controller.closeView(log.logDescription ?? '');
          controller.text =
              log.logName ?? log.logDescription ?? _HistoryLogCard._resolveLogLabel(log);
        },
      ),
    );
  }

  List<LogEntry> get _filteredLogs {
    final logs = _logs;
    if (logs == null) return const <LogEntry>[];
    final query = _searchController.text.trim().toLowerCase();
    final startDate = _rangeStartDate(_range);
    final filtered = logs.where((log) {
      final matchesRange = startDate == null || log.logTime.isAfter(startDate);
      final matchesQuery =
          query.isEmpty ? true : _logMatchesQuery(log, query);
      return matchesRange && matchesQuery;
    }).toList()
      ..sort((a, b) => b.logTime.compareTo(a.logTime));
    return filtered;
  }

  bool get _hasActiveFilters {
    return _range != HistoryRange.all ||
        _searchController.text.trim().isNotEmpty;
  }

  DateTime? _rangeStartDate(HistoryRange range) {
    final now = DateTime.now();
    switch (range) {
      case HistoryRange.day:
        return now.subtract(const Duration(hours: 24));
      case HistoryRange.week:
        return now.subtract(const Duration(days: 7));
      case HistoryRange.month:
        return now.subtract(const Duration(days: 30));
      case HistoryRange.all:
        return null;
    }
  }

  bool _logMatchesQuery(LogEntry log, String query) {
    bool matches(String? value) =>
        value != null && value.toLowerCase().contains(query);
    final label = _HistoryLogCard._resolveLogLabel(log).toLowerCase();
    if (label.contains(query)) return true;
    if (matches(log.logDescription)) return true;
    if (matches(log.logName)) return true;
    if (matches(log.userLog)) return true;
    final timeStrings = [
      DateFormat('MMM d, h:mm a').format(log.logTime),
      DateFormat('y-MM-dd').format(log.logTime),
    ];
    return timeStrings.any((value) => value.toLowerCase().contains(query));
  }

  Widget _buildLogList() {
    final selectedSubUser = _findSubUserById(_selectedSubUserId);
    if (selectedSubUser == null) {
      return const Center(child: Text('Select a sub-user to view logs.'));
    }
    if (_loadingLogs && _logs == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
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
    final visibleLogs = _filteredLogs;
    final theme = Theme.of(context);
    final emptyMessage = _hasActiveFilters
        ? 'No logs match the current filters.'
        : 'No logs found for ${selectedSubUser.name}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log history for ${selectedSubUser.name}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator.adaptive(
            edgeOffset: 12,
            onRefresh: _refreshLogs,
            child: visibleLogs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 12,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              emptyMessage,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _logScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) =>
                        _HistoryLogCard(log: visibleLogs[index]),
                    separatorBuilder: _buildLogSeparator,
                    itemCount: visibleLogs.length,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogSeparator(BuildContext context, int index) =>
      const SizedBox(height: 12);

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
      _subUserFieldController.clear();
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
      });
      if (defaultSelection != null) {
        if (pendingInitialSelection != null &&
            pendingInitialSelection == defaultSelection.subUserId) {
          setState(() => _initialSubUserId = null);
        }
        _applySubUserSelection(defaultSelection);
      } else {
        setState(() {
          _selectedSubUserId = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subUsersError = friendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSubUsers = false);
      }
    }
  }

  Future<void> _loadLogsFor(
    SubUserModel subUser, {
    bool clearExisting = true,
  }) async {
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
      if (clearExisting) {
        _logs = null;
      }
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
        _logsError = friendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loadingLogs = false);
      }
    }
  }

  Future<void> _refreshLogs() async {
    final selectedId = _selectedSubUserId;
    if (selectedId == null) return;
    final selected = _findSubUserById(selectedId);
    if (selected == null) return;
    await _loadLogsFor(selected, clearExisting: false);
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
    final description = log.logDescription?.trim() ?? '';
    final hasDescription = description.isNotEmpty;

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
            value: hasDescription ? description : 'No description provided',
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
