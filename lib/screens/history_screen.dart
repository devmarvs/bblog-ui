import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _userIdCtrl = TextEditingController();
  final _subUserIdCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  List<LogEntry>? _items;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _subUserIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdCtrl,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subUserIdCtrl,
              decoration: const InputDecoration(labelText: 'Sub-user ID'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Load History',
              loading: _loading,
              onPressed: _loading ? null : _load,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

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
      return const Center(child: Text('Enter IDs and load history'));
    }
    if (_items!.isEmpty) {
      return const Center(child: Text('No logs found'));
    }
    final formatter = DateFormat.yMd().add_jm();
    return ListView.separated(
      itemCount: _items!.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final log = _items![index];
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(logsRepositoryProvider);
    try {
      final data = await repo.listBySubUser(
        _userIdCtrl.text.trim(),
        _subUserIdCtrl.text.trim(),
      );
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
}
