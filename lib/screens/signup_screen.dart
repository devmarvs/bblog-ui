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

enum AccountRole { parent, caregiver, supporter }

extension on AccountRole {
  String get label {
    switch (this) {
      case AccountRole.parent:
        return 'Parent';
      case AccountRole.caregiver:
        return 'Caregiver';
      case AccountRole.supporter:
        return 'Support crew';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountRole.parent:
        return Icons.family_restroom;
      case AccountRole.caregiver:
        return Icons.volunteer_activism;
      case AccountRole.supporter:
        return Icons.groups_2;
    }
  }

  String get description {
    switch (this) {
      case AccountRole.parent:
        return 'Full access for primary guardians.';
      case AccountRole.caregiver:
        return 'Hands-on support role with logging access.';
      case AccountRole.supporter:
        return 'View-only helpers who cheer from afar.';
    }
  }
}

const List<String> _countryOptions = [
  'United States',
  'Canada',
  'United Kingdom',
  'Australia',
  'Germany',
  'France',
  'Brazil',
  'India',
  'Japan',
  'Other',
];

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  AccountRole _role = AccountRole.parent;

  List<ButtonSegment<AccountRole>> get _roleSegments =>
      AccountRole.values
          .map(
            (role) => ButtonSegment<AccountRole>(
              value: role,
              icon: Icon(role.icon),
              label: Text(role.label),
            ),
          )
          .toList();

  final List<DropdownMenuEntry<String>> _countryEntries = _countryOptions
      .map(
        (country) => DropdownMenuEntry<String>(
          value: country == 'Other' ? '' : country,
          label: country,
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
    final roleDescription = _role.description;
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
                    SegmentedButton<AccountRole>(
                      segments: _roleSegments,
                      selected: <AccountRole>{_role},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        setState(() => _role = selection.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      roleDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
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
                      label: const Text('Country (optional)'),
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
                        labelText: 'Phone (optional)',
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
                              country: _country.text.isEmpty
                                  ? null
                                  : _country.text.trim(),
                              phone: _phone.text.isEmpty
                                  ? null
                                  : _phone.text.trim(),
                            );
                        if (!context.mounted) return;
                        if (success) {
                          final email = _email.text.trim();
                          final snackText =
                              'Thanks, ${_role.label}! Verification email sent to $email';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(snackText)),
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
                        style: const TextStyle(color: Colors.red),
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
