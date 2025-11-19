import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _HelpAction {
  const _HelpAction({
    required this.label,
    required this.icon,
    required this.path,
    this.description,
    this.includeEmail = false,
  });

  final String label;
  final IconData icon;
  final String path;
  final String? description;
  final bool includeEmail;

  String route(String email) {
    if (!includeEmail || email.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {'email': email}).toString();
  }
}

const List<_HelpAction> _helpActions = [
  _HelpAction(
    label: 'Forgot password',
    icon: Icons.lock_reset,
    path: '/forgot-password',
    description: 'Send a reset link to your inbox.',
    includeEmail: true,
  ),
  _HelpAction(
    label: 'Verify email',
    icon: Icons.mark_email_unread_outlined,
    path: '/verify-email',
    description: 'Resend your verification email.',
    includeEmail: true,
  ),
  _HelpAction(
    label: 'Create an account',
    icon: Icons.person_add_alt,
    path: '/signup',
    description: 'Need an account? Start here.',
  ),
];

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final SearchController _helpSearchController = SearchController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _helpSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: buildBackButton(context),
        title: const Text('Log in'),
        actions: [
          OverflowMenuButton(
            tooltip: 'Navigate',
            actions: [
              OverflowAction(
                label: 'Home',
                icon: Icons.home_outlined,
                onPressed: () => context.go('/home'),
              ),
              OverflowAction(
                label: 'Sign up',
                icon: Icons.person_add_alt,
                onPressed: () => context.go('/signup'),
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
                  children: [
                    const BrandLogo(size: 140),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pwCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Log in',
                      loading: auth.loading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await ref
                              .read(authControllerProvider.notifier)
                              .login(_emailCtrl.text.trim(), _pwCtrl.text);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SearchAnchor.bar(
                      searchController: _helpSearchController,
                      barHintText: 'Need help? Try searching…',
                      viewHintText: 'Search help actions',
                      suggestionsBuilder: (context, controller) {
                        final query = controller.text.trim().toLowerCase();
                        final matches = _helpActions.where(
                          (action) =>
                              query.isEmpty ||
                              action.label.toLowerCase().contains(query) ||
                              (action.description != null &&
                                  action.description!
                                      .toLowerCase()
                                      .contains(query)),
                        );
                        final results = matches.toList();
                        if (results.isEmpty) {
                          return [
                            const ListTile(
                              leading: Icon(Icons.search_off),
                              title: Text('No help topics match'),
                              subtitle: Text('Try a different search term.'),
                            ),
                          ];
                        }
                        return results.map(
                          (action) => ListTile(
                            leading: Icon(action.icon),
                            title: Text(action.label),
                            subtitle: action.description == null
                                ? null
                                : Text(action.description!),
                            onTap: () {
                              controller.closeView(action.label);
                              final email = _emailCtrl.text.trim();
                              context.go(action.route(email));
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('Create an account'),
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
