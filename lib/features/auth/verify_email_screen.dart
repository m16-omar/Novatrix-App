import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user.dart';
import '../shell/workspace.dart';

const _codeLength = 6;
const _resendSeconds = 60;

/// Confirms a learner's or client's email with the 6-digit code the backend emails at sign-up.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.from, this.sendOnOpen = false});

  /// Where to go once confirmed. Defaults to the person's main area.
  final String? from;

  /// Ask for a fresh code on arrival: coming from log in, the sign-up code may have expired.
  final bool sendOnOpen;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  late int _cooldown = widget.sendOnOpen ? 0 : _resendSeconds;
  bool _busy = false;
  bool _sending = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _startCooldown(_cooldown);
    if (widget.sendOnOpen) WidgetsBinding.instance.addPostFrameCallback((_) => _resend());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  void _continue() {
    final session = ref.read(sessionProvider).value;
    final target = widget.from ?? (session == null ? '/' : Workspace.primaryFor(session.roles).home);
    context.go(target);
  }

  void _markVerified([User? user]) {
    final current = ref.read(sessionProvider).value?.user;
    if (current == null) return;
    ref.read(sessionProvider.notifier).setUser(user ?? current.copyWith(emailVerified: true));
    _continue();
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _error = null;
      _notice = null;
    });
    try {
      final alreadyVerified = await ref.read(authRepositoryProvider).sendVerificationCode();
      if (alreadyVerified) return _markVerified();
      final email = ref.read(sessionProvider).value?.user.email ?? 'your email';
      setState(() => _notice = 'We sent a new code to $email.');
      _code.clear();
      _focus.requestFocus();
      _startCooldown(_resendSeconds);
    } on ApiException catch (e) {
      if (e.code == 'resend_too_soon') {
        _startCooldown(e.info['retry_after_seconds'] ?? _resendSeconds);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    final code = _code.text;
    if (_busy) return;
    if (code.length != _codeLength) {
      setState(() => _error = 'Enter all $_codeLength digits from the email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).verifyEmail(code);
      if (mounted) _markVerified(user);
    } on ApiException catch (e) {
      _code.clear();
      _focus.requestFocus();
      final left = e.info['attempts_left'];
      setState(() => _error = e.code == 'code_invalid' && left != null
          ? (left > 0
              ? '${e.message} $left ${left == 1 ? 'try' : 'tries'} left.'
              : "That code is not right, and it can't be used again. Ask for a new code.")
          : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useDifferentEmail() async {
    await ref.read(sessionProvider.notifier).logout();
    if (mounted) context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = ref.watch(sessionProvider).value?.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: pagePadding,
          child: EmptyState(
            icon: LucideIcons.logIn,
            title: 'Log in to confirm your email.',
            action: GradientButton(label: 'Log in', expand: false, onPressed: () => context.go('/login')),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: p.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(LucideIcons.mailCheck, size: 32, color: p.brand),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Confirm your email', style: context.text.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'We sent a $_codeLength-digit code to '),
                      TextSpan(text: user.email, style: TextStyle(color: p.foreground, fontWeight: FontWeight.w600)),
                      const TextSpan(text: '. It expires in 15 minutes.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: p.mutedForeground, height: 1.45),
                ),
                const SizedBox(height: 28),
                if (_error != null) ...[ErrorNote(_error!), const SizedBox(height: 16)],
                if (_notice != null && _error == null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: p.muted, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mailCheck, size: 18, color: p.brand),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_notice!, style: context.text.bodyMedium)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                OtpField(
                  controller: _code,
                  focusNode: _focus,
                  length: _codeLength,
                  enabled: !_busy,
                  hasError: _error != null,
                  onCompleted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  key: const ValueKey('verify-submit'),
                  label: 'Confirm email',
                  busy: _busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: _cooldown > 0
                      ? Text("Didn't get a code? Send a new one in ${_cooldown}s", style: context.text.bodySmall)
                      : TextButton(
                          onPressed: _sending ? null : _resend,
                          child: Text(_sending ? 'Sending…' : "Didn't get a code? Send a new one"),
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Can't find it? Check your spam folder, or contact ${AppConfig.supportEmail}.",
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: _useDifferentEmail,
                    style: TextButton.styleFrom(foregroundColor: p.mutedForeground),
                    child: const Text('Wrong email? Sign up again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Six digit boxes over one hidden text field, so pasting and the keyboard's
/// "From Messages/Mail" code suggestion fill every box at once.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.length,
    this.enabled = true,
    this.hasError = false,
    this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = widget.controller.text;
    final focused = widget.focusNode.hasFocus;
    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: focused && i == text.length.clamp(0, widget.length - 1) ? 2 : 1.2,
                        color: widget.hasError
                            ? p.destructive
                            : focused && i == text.length.clamp(0, widget.length - 1)
                                ? p.brand
                                : i < text.length
                                    ? p.brand.withValues(alpha: 0.5)
                                    : p.border,
                      ),
                    ),
                    child: Text(
                      i < text.length ? text[i] : '',
                      style: context.text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // The real input: invisible, covering the boxes so a tap anywhere focuses it.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const ValueKey('otp-input'),
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
                onChanged: (value) {
                  if (value.length == widget.length) widget.onCompleted?.call(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
