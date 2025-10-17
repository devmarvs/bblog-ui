import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/log_entry.dart';
import '../providers/repository_providers.dart';
import '../widgets/common.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userLog = TextEditingController();
  final _subUserId = TextEditingController();
  final _logTypeId = TextEditingController(text: '1');
  final _logName = TextEditingController();
  final _logDesc = TextEditingController();

  DateTime _logTime = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _userLog.dispose();
    _subUserId.dispose();
    _logTypeId.dispose();
    _logName.dispose();
    _logDesc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat.yMd().add_jm().format(_logTime);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _userLog,
                decoration: const InputDecoration(labelText: 'User ID'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Enter a user ID' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subUserId,
                decoration: const InputDecoration(labelText: 'Sub-user ID'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Enter a sub-user ID'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logTypeId,
                decoration: const InputDecoration(labelText: 'Log type ID'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Enter a type' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logName,
                decoration: const InputDecoration(
                  labelText: 'Log name (optional)',
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
                label: 'Save',
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final repo = ref.read(logsRepositoryProvider);
    final entry = LogEntry(
      userLog: _userLog.text.trim(),
      subUserId: _subUserId.text.trim(),
      logTypeId: int.tryParse(_logTypeId.text.trim()) ?? 1,
      logName: _logName.text.trim().isEmpty ? null : _logName.text.trim(),
      logTime: _logTime,
      logDescription: _logDesc.text.trim().isEmpty
          ? null
          : _logDesc.text.trim(),
    );

    try {
      await repo.createLog(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log created')));
      _logName.clear();
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
