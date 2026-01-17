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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _codeCtrl;
  late final VoidCallback _emailListener;
  late final String? _email;
  bool _resending = false;
  bool _verifying = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    final storedEmail = ref
        .read(authControllerProvider)
        .pendingVerificationEmail;
    _email = widget.initialEmail ?? storedEmail;
    _emailCtrl = TextEditingController(text: _email ?? '');
    _codeCtrl = TextEditingController();
    _emailListener = () => setState(() {});
    _emailCtrl.addListener(_emailListener);
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_emailListener);
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emailForCopy = _emailCtrl.text.trim();
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
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      emailForCopy.isEmpty
                          ? 'Enter your email and the verification code we sent to activate your account.'
                          : 'Enter the verification code we sent to $emailForCopy.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        helperText: 'Use the email you registered with',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Verification code',
                        helperText: 'Check your inbox or spam folder',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the code from your email';
                        }
                        if (value.trim().length < 4) {
                          return 'Code looks too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Verify and activate',
                      loading: _verifying,
                      onPressed: _verifying ? null : _submit,
                    ),
                    const SizedBox(height: 12),
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
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
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
          .requestEmailVerification(email: email);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmEmailVerification(email: email, verificationCode: code);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _info = 'Email verified! You can log in now.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! You can log in with your password.'),
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }
}
