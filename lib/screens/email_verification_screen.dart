import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/error_message.dart';
import '../providers/auth_providers.dart';
import '../widgets/common.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  late final String? _email;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    final storedEmail = ref
        .read(authControllerProvider)
        .pendingVerificationEmail;
    _email = widget.initialEmail ?? storedEmail;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('Verify your email'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _email == null || _email!.isEmpty
                      ? 'Check your email inbox and spam folder for the verification message.'
                      : 'We sent a verification email to $_email.\nPlease check your inbox and spam folder.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Didn't get the email? Resend"),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to login'),
                ),
                if (_info != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _info!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resend() async {
    if (_email == null || _email!.trim().isEmpty) {
      setState(() {
        _error = 'Email missing. Return to login and try again.';
        _info = null;
      });
      return;
    }
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestEmailVerification(email: _email!.trim());
      if (!mounted) return;
      setState(() {
        _resending = false;
        _info = 'Verification email sent. Check your inbox and spam folder.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }
}
