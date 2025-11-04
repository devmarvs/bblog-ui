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
  SubUserModel? _selectedSubUser;
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
          _selectedSubUser = null;
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
          children: [
            Expanded(
              flex: 1,
              child: _buildSubUserList(userId),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: _buildLogList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubUserList(String? userId) {
    if (_loadingSubUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userId == null) {
      return const Center(child: Text('Sign in to view sub-users.'));
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
      return const Center(child: Text('No sub-users found.'));
    }
    return ListView.separated(
      itemCount: _subUsers!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final subUser = _subUsers![index];
        final isSelected = _selectedSubUser?.subUserId == subUser.subUserId;
        return ListTile(
          title: Text(subUser.name),
          subtitle: subUser.description != null
              ? Text(subUser.description!)
              : null,
          trailing:
              isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
          selected: isSelected,
          onTap: () => _loadLogsFor(subUser),
        );
      },
    );
  }

  Widget _buildLogList() {
    if (_selectedSubUser == null) {
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
        child: Text('No logs found for ${_selectedSubUser!.name}.'),
      );
    }
    final formatter = DateFormat.yMd().add_jm();
    return ListView.separated(
      itemCount: _logs!.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final log = _logs![index];
        return ListTile(
          leading: const Icon(Icons.event_note),
          title: Text(
            log.logName ?? 'Log #${index + 1} (type ${log.logTypeId})',
          ),
          subtitle: Text(log.logDescription ?? ''),
          trailing: Text(formatter.format(log.logTime)),
        );
      },
    );
  }

  Future<void> _loadSubUsers(String userId) async {
    setState(() {
      _loadingSubUsers = true;
      _subUsersError = null;
      _subUsers = null;
      _selectedSubUser = null;
      _logs = null;
      _logsError = null;
    });
    final repo = ref.read(subUserRepositoryProvider);
    try {
      final data = await repo.list(userId);
      if (!mounted) return;
      setState(() => _subUsers = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _subUsersError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loadingSubUsers = false);
    }
  }

  Future<void> _loadLogsFor(SubUserModel subUser) async {
    final authState = ref.read(authControllerProvider);
    final userId = authState.userId;
    if (userId == null) {
      setState(() {
        _selectedSubUser = subUser;
        _logsError = 'Unable to determine user ID.';
        _logs = null;
      });
      return;
    }
    setState(() {
      _selectedSubUser = subUser;
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
}
