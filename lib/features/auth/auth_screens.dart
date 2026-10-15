import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/widgets.dart';
import '../shell/workspace.dart';

enum _Audience {
  learner('Learner', LucideIcons.graduationCap, 'Access your courses, lessons, progress, and certificates.'),
  facilitator('Facilitator', LucideIcons.presentation, 'Follow your learners and review their work.'),
  client('Client', LucideIcons.briefcase, 'Follow your projects, open shared documents, and track support.');

  const _Audience(this.label, this.icon, this.intro);
  final String label;
  final IconData icon;
  final String intro;
}

/// Opening log in or sign up while already signed in goes straight to the right area.
/// (Done here rather than in the router, so the login screen can still show a notice
/// right after signing in.)
void _leaveIfSignedIn(WidgetRef ref, BuildContext context, String? from) {
  final session = ref.read(sessionProvider).value;
  if (session == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) context.go(from ?? Workspace.primaryFor(session.roles).home);
  });
}

/// The layout shared by the login, sign-up, and reset screens.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.intro, required this.children, this.showLogo = false});

  final String title;
  final String intro;
  final List<Widget> children;

  /// Shows the logo centred above the title (the log-in screen).
  final bool showLogo;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(toolbarHeight: showLogo ? 8 : kToolbarHeight),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  if (showLogo) ...[
                    const Center(child: NovatrixLogo(height: 72)),
                    const SizedBox(height: 32),
                  ],
                  Text(title, style: context.text.headlineSmall),
                  const SizedBox(height: 6),
                  Text(intro, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedForeground)),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );
}

/// "New to Novatrix? Create account": a muted question and a link.
class _SwitchLink extends StatelessWidget {
  const _SwitchLink(this.question, this.action, this.onTap);

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            Text(question, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedForeground)),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 40)),
              child: Text(action),
            ),
          ],
        ),
      );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.audience, this.from});

  final String? audience;
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late _Audience _audience =
      _Audience.values.firstWhere((a) => a.name == widget.audience, orElse: () => _Audience.learner);
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _leaveIfSignedIn(ref, context, widget.from);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _notice = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final session = await ref.read(sessionProvider.notifier).login(_email.text, _password.text);
      if (!mounted) return;
      final roles = session.roles;
      if (_audience == _Audience.facilitator && !roles.isFacilitator) {
        setState(() => _notice = "You're signed in, but this account doesn't have facilitator access yet. "
            'Facilitator accounts are set up by The Novatrix — contact ${AppConfig.supportEmail} if you should have one.');
        return;
      }
      final target = switch (_audience) {
        _Audience.facilitator => '/teach',
        _Audience.client => '/client',
        _Audience.learner => widget.from ?? Workspace.primaryFor(roles).home,
      };
      // Learners and clients confirm their email first, with a fresh code: the sign-up one may have
      // expired. Facilitator accounts are set up by The Novatrix.
      context.go(_audience != _Audience.facilitator && session.user.needsEmailVerification
          ? '/verify-email?send=1&from=${Uri.encodeComponent(target)}'
          : target);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _AuthScaffold(
      showLogo: true,
      title: 'Welcome back',
      intro: 'Sign in to continue to Novatrix',
      children: [
        if (_notice != null) ...[
          ErrorNote(_notice!, title: 'No facilitator access'),
          const SizedBox(height: 16),
          SecondaryButton(label: 'Continue to my learning', onPressed: () => context.go('/learn')),
        ] else
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<_Audience>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: p.brand,
                      selectedForegroundColor: Colors.white,
                      side: BorderSide(color: p.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    segments: [
                      for (final a in _Audience.values)
                        ButtonSegment(value: a, label: Text(a.label), icon: Icon(a.icon, size: 16)),
                    ],
                    selected: {_audience},
                    onSelectionChanged: (s) => setState(() => _audience = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(_audience.intro, style: context.text.bodySmall),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    ErrorNote(_error!, title: "We couldn't log you in."),
                    const SizedBox(height: 16),
                  ],
                  LabeledField(
                    label: 'Email address',
                    showLabel: false,
                    icon: LucideIcons.mail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Password',
                    showLabel: false,
                    icon: LucideIcons.lock,
                    controller: _password,
                    obscure: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    key: const ValueKey('login-submit'),
                    label: 'Log in',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: switch (_audience) {
                      _Audience.facilitator => Text(
                          'Facilitator accounts are created by The Novatrix. Ask your course lead for access.',
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall,
                        ),
                      _Audience.client =>
                        _SwitchLink('New client?', 'Create account', () => context.push('/signup?from=/client')),
                      _Audience.learner => _SwitchLink(
                          'New to Novatrix?',
                          'Create account',
                          () => context.push(
                            widget.from == null ? '/signup' : '/signup?from=${Uri.encodeComponent(widget.from!)}',
                          ),
                        ),
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.from});
  final String? from;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _leaveIfSignedIn(ref, context, widget.from);
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).register(
            email: _email.text,
            password: _password.text,
            firstName: _first.text,
            lastName: _last.text,
            phone: _phone.text,
          );
      // The backend has just emailed a 6-digit code: confirm it, then carry on.
      if (mounted) context.go('/verify-email?from=${Uri.encodeComponent(widget.from ?? '/learn')}');
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Create your account',
        intro: 'Start building your next step with Novatrix',
        children: [
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                children: [
                  if (_error != null) ...[
                    ErrorNote(_error!.fieldErrors.isEmpty ? _error!.message : 'Please check the highlighted fields.',
                        title: "We couldn't create your account."),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'First name',
                          showLabel: false,
                          icon: LucideIcons.user,
                          controller: _first,
                          autofillHints: const [AutofillHints.givenName],
                          errorText: _error?.field('first_name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Last name',
                          showLabel: false,
                          controller: _last,
                          autofillHints: const [AutofillHints.familyName],
                          errorText: _error?.field('last_name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Email address',
                    showLabel: false,
                    icon: LucideIcons.mail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                    errorText: _error?.field('email'),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Phone',
                    showLabel: false,
                    icon: LucideIcons.phone,
                    controller: _phone,
                    optional: true,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    errorText: _error?.field('phone'),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Password',
                    showLabel: false,
                    icon: LucideIcons.lock,
                    controller: _password,
                    obscure: true,
                    helper: 'At least 8 characters. Avoid common or all-number passwords.',
                    autofillHints: const [AutofillHints.newPassword],
                    validator: validateNewPassword,
                    errorText: _error?.field('password'),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Confirm password',
                    showLabel: false,
                    icon: LucideIcons.lock,
                    controller: _confirm,
                    obscure: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => v != _password.text ? "The passwords don't match." : null,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      text: 'By creating an account, you agree to the ',
                      children: [
                        TextSpan(
                          text: 'Terms of Use',
                          style: TextStyle(color: context.palette.brand, fontWeight: FontWeight.w600),
                          recognizer: _termsTap,
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: context.palette.brand, fontWeight: FontWeight.w600),
                          recognizer: _privacyTap,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(label: 'Create account', busy: _busy, onPressed: _submit),
                  const SizedBox(height: 12),
                  _SwitchLink('Already have an account?', 'Log in', () => context.go('/login')),
                  const SizedBox(height: 8),
                  Text(
                    'Facilitators: your account is set up by The Novatrix. '
                    'Clients: sign up with the email your project lead has on file.',
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => openLink(context, '${AppConfig.siteUrl}/legal/privacy-policy');
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => openLink(context, '${AppConfig.siteUrl}/legal/terms-of-use');
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_email.text);
      setState(() => _sent = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Reset your password',
        intro: "Enter your account's email and we'll send you a link to choose a new password.",
        children: [
          if (_sent)
            EmptyState(
              icon: LucideIcons.mail,
              title: 'Check your email',
              message: 'If an account exists for ${_email.text.trim()}, a reset link is on its way. '
                  'The link opens in your browser; then come back and log in.',
              action: SecondaryButton(label: 'Back to log in', expand: false, onPressed: () => context.go('/login')),
            )
          else
            Form(
              key: _form,
              child: Column(
                children: [
                  if (_error != null) ...[ErrorNote(_error!), const SizedBox(height: 16)],
                  LabeledField(
                    label: 'Email address',
                    showLabel: false,
                    icon: LucideIcons.mail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(label: 'Send reset link', busy: _busy, onPressed: _submit),
                ],
              ),
            ),
        ],
      );
}
