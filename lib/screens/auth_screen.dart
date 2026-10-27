import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../ui/widgets.dart';

/// Sign-in screen. With accounts (Firebase mode) it offers email/password and
/// Google; in demo mode the only option is to continue as a guest.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_register) {
      await auth.signUpWithEmail(_email.text, _password.text, _name.text);
    } else {
      await auth.signInWithEmail(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ExcludeSemantics(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 44,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConfig.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn IT and computing terms, one quiz at a time.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (auth.error != null) ...[
                    InlineError(message: auth.error!),
                    const SizedBox(height: 16),
                  ],
                  if (auth.supportsAccounts)
                    ..._accountForm(auth, theme)
                  else
                    ..._guestOptions(auth, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _guestOptions(AuthProvider auth, ThemeData theme) {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.science_outlined, color: theme.colorScheme.tertiary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You are in demo mode. Everything runs on this device with '
                  'a sample dictionary and fictional community members. '
                  'No account is needed.',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: auth.busy ? null : auth.signInAsGuest,
        icon: auth.busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward),
        label: const Text('Continue as guest'),
      ),
    ];
  }

  List<Widget> _accountForm(AuthProvider auth, ThemeData theme) {
    return [
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_register) ...[
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a display name'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Enter your email address';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Use at least 6 characters'
                  : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: auth.busy ? null : _submit,
        child: auth.busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_register ? 'Create account' : 'Sign in'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: auth.busy ? null : auth.signInWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Continue with Google'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () {
          context.read<AuthProvider>().clearError();
          setState(() => _register = !_register);
        },
        child: Text(
          _register
              ? 'I already have an account'
              : 'New here? Create an account',
        ),
      ),
    ];
  }
}
