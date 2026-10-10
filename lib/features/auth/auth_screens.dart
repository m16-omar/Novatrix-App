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

/// The centred card used by the login, sign-up, and reset screens.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.eyebrow, required this.title, required this.intro, required this.children});

  final String eyebrow;
  final String title;
  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const NovatrixLogo(height: 32)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  PageHeader(eyebrow: eyebrow, title: title, intro: intro),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
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
      context.go(target);
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
      eyebrow: 'Welcome back',
      title: 'Log in',
      intro: _audience.intro,
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
                  Text("I'm logging in as", style: context.text.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<_Audience>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: p.brand,
                      selectedForegroundColor: Colors.white,
                      side: BorderSide(color: p.border),
                    ),
                    segments: [
                      for (final a in _Audience.values)
                        ButtonSegment(value: a, label: Text(a.label), icon: Icon(a.icon, size: 16)),
                    ],
                    selected: {_audience},
                    onSelectionChanged: (s) => setState(() => _audience = s.first),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    ErrorNote(_error!, title: "We couldn't log you in."),
                    const SizedBox(height: 16),
                  ],
                  LabeledField(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Password',
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
                      child: const Text('Forgot your password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: 'Log in as ${_audience.label.toLowerCase()}',
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
                      _Audience.client => TextButton(
                          onPressed: () => context.go('/signup?from=/client'),
                          child: const Text('New client? Create an account', textAlign: TextAlign.center),
                        ),
                      _Audience.learner => TextButton(
                          onPressed: () => context.go(
                            widget.from == null ? '/signup' : '/signup?from=${Uri.encodeComponent(widget.from!)}',
                          ),
                          child: const Text('New to Novatrix? Create a new learner account'),
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
  bool _busy = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _leaveIfSignedIn(ref, context, widget.from);
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password]) {
      c.dispose();
    }
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
      if (mounted) context.go(widget.from ?? '/learn');
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        eyebrow: 'Get started',
        title: 'Create your account',
        intro: 'Enroll in courses, track your progress, and download your certificates.',
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
                  LabeledField(
                    label: 'First name',
                    controller: _first,
                    autofillHints: const [AutofillHints.givenName],
                    errorText: _error?.field('first_name'),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Last name',
                    controller: _last,
                    autofillHints: const [AutofillHints.familyName],
                    errorText: _error?.field('last_name'),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                    errorText: _error?.field('email'),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Phone',
                    controller: _phone,
                    optional: true,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    errorText: _error?.field('phone'),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Password',
                    controller: _password,
                    obscure: true,
                    helper: 'At least 8 characters. Avoid common or all-number passwords.',
                    autofillHints: const [AutofillHints.newPassword],
                    validator: validateNewPassword,
                    errorText: _error?.field('password'),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(label: 'Create account', busy: _busy, onPressed: _submit),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Log in'),
                  ),
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
        eyebrow: 'Account help',
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
                    label: 'Email',
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
