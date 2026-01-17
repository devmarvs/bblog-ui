import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/common.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

const List<Map<String, String>> _countryOptions = [
  {'code': 'US', 'label': 'US - United States'},
  {'code': 'CA', 'label': 'CA - Canada'},
  {'code': 'GB', 'label': 'GB - United Kingdom'},
  {'code': 'AU', 'label': 'AU - Australia'},
  {'code': 'DE', 'label': 'DE - Germany'},
  {'code': 'FR', 'label': 'FR - France'},
  {'code': 'BR', 'label': 'BR - Brazil'},
  {'code': 'IN', 'label': 'IN - India'},
  {'code': 'JP', 'label': 'JP - Japan'},
  {'code': '', 'label': 'Other'},
];

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();

  final List<DropdownMenuEntry<String>> _countryEntries = _countryOptions
      .map(
        (country) => DropdownMenuEntry<String>(
          value: country['code'] ?? '',
          label: country['label'] ?? '',
        ),
      )
      .toList();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _country.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('Create account'),
        actions: [
          OverflowMenuButton(
            actions: [
              OverflowAction(
                label: 'Log in',
                icon: Icons.login,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter username' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      controller: _country,
                      label: const Text('Country code (optional)'),
                      dropdownMenuEntries: _countryEntries,
                      leadingIcon: const Icon(Icons.public),
                      enableFilter: true,
                      enableSearch: true,
                      requestFocusOnTap: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile (optional)',
                        helperText: 'Include country code, e.g. +15005550000',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Create account',
                      loading: auth.loading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signup(
                              username: _username.text.trim(),
                              email: _email.text.trim(),
                              password: _password.text,
                              countryCode: _country.text.trim().isEmpty
                                  ? null
                                  : _country.text.trim(),
                              mobile: _phone.text.trim().isEmpty
                                  ? null
                                  : _phone.text.trim(),
                            );
                        if (!context.mounted) return;
                        if (success) {
                          final email = _email.text.trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Thanks! Verification email sent to $email',
                              ),
                            ),
                          );
                          context.go(
                            Uri(
                              path: '/verify-email',
                              queryParameters: {'email': email},
                            ).toString(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Log in'),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        auth.error!,
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
}
