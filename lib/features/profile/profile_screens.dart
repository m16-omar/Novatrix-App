import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user.dart';
import '../learner/learner_screens.dart' show LearningTotals;
import '../shell/app_shell.dart';
import '../shell/workspace.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    if (session == null) return const Scaffold(body: LoadingView());
    final user = session.user;
    final roles = session.roles;
    final workspace = Workspace.forPath('/profile', roles);
    final areas = Workspace.available(roles);
    final p = context.palette;

    return Scaffold(
      appBar: WorkspaceAppBar(workspace: workspace),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionProvider.notifier).refreshRoles();
          ref.invalidate(enrollmentsProvider);
        },
        child: ListView(
          padding: pagePadding,
          children: [
            AppCard(
              child: Column(
                children: [
                  Avatar(user: user, size: 84),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: context.text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (areas.contains(Workspace.learner)) const Pill('Learner'),
                      if (roles.isFacilitator) const Pill('Facilitator'),
                      if (roles.hasClientProjects) const Pill('Client'),
                    ],
                  ),
                  if (user.profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(user.profile.bio, textAlign: TextAlign.center, style: context.text.bodySmall),
                  ],
                  const SizedBox(height: 16),
                  _Detail(LucideIcons.mail, 'Email', user.email),
                  _Detail(LucideIcons.phone, 'Phone', user.profile.phone),
                  _Detail(LucideIcons.mapPin, 'Location', user.profile.location),
                  _Detail(LucideIcons.calendar, 'Member since', formatDate(user.dateJoined)),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Edit details',
                    icon: LucideIcons.userPen,
                    onPressed: () => context.go('/profile/edit'),
                  ),
                ],
              ),
            ),
            if (areas.contains(Workspace.learner)) const _LearningSummary(),
            if (areas.length > 1) ...[
              const SectionTitle('My areas'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, w) in areas.indexed) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        leading: Icon(switch (w) {
                          Workspace.learner => LucideIcons.graduationCap,
                          Workspace.facilitator => LucideIcons.presentation,
                          Workspace.client => LucideIcons.briefcase,
                          Workspace.public => LucideIcons.globe,
                        }),
                        title: Text(switch (w) {
                          Workspace.learner => 'My learning',
                          Workspace.facilitator => 'Teaching dashboard',
                          Workspace.client => 'Client dashboard',
                          Workspace.public => 'Novatrix',
                        }),
                        trailing: const Icon(LucideIcons.chevronRight, size: 18),
                        onTap: () => context.go(w.home),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SectionTitle('Settings'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.keyRound),
                    title: const Text('Change password'),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => context.go('/profile/password'),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appearance', style: context.text.titleMedium),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: p.brand,
                              selectedForegroundColor: Colors.white,
                              side: BorderSide(color: p.border),
                            ),
                            segments: const [
                              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(LucideIcons.monitor, size: 16)),
                              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(LucideIcons.sun, size: 16)),
                              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(LucideIcons.moon, size: 16)),
                            ],
                            selected: {ref.watch(themeModeProvider)},
                            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(LucideIcons.globe),
                    title: const Text('Explore Novatrix'),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () => context.go('/'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(LucideIcons.shieldCheck),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(LucideIcons.externalLink, size: 16),
                    onTap: () => openLink(context, '${AppConfig.siteUrl}/legal/privacy-policy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              label: 'Log out',
              icon: LucideIcons.logOut,
              onPressed: () async {
                await ref.read(sessionProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: p.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall),
                Text(
                  value.isEmpty ? 'Not added' : value,
                  style: TextStyle(color: value.isEmpty ? p.mutedForeground : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSummary extends ConsumerWidget {
  const _LearningSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(enrollmentsProvider).value;
    if (enrollments == null || enrollments.isEmpty) return const SizedBox.shrink();
    final totals = LearningTotals(enrollments);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Learning progress'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressLine(value: totals.average, label: 'Overall progress'),
              const SizedBox(height: 10),
              Text(
                '${plural(totals.courses, 'course')} · ${plural(totals.lessonsDone, 'lesson')} completed · '
                '${plural(totals.certificates, 'certificate')}',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final e in enrollments)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: () => context.go('/learn/course/${e.course.slug}'),
                    child: ProgressLine(
                      value: e.progress,
                      label: e.isCompleted ? '${e.course.title} · Completed' : e.course.title,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final Profile _initial = ref.read(sessionProvider).value?.user.profile ?? const Profile();
  late final _first = TextEditingController(text: _initial.firstName);
  late final _last = TextEditingController(text: _initial.lastName);
  late final _phone = TextEditingController(text: _initial.phone);
  late final _country = TextEditingController(text: _initial.country);
  late final _city = TextEditingController(text: _initial.stateOrCity);
  late final _bio = TextEditingController(text: _initial.bio);
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _country, _city, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = await ref.read(authRepositoryProvider).updateProfile(Profile(
            firstName: _first.text,
            lastName: _last.text,
            phone: _phone.text,
            country: _country.text,
            stateOrCity: _city.text,
            bio: _bio.text,
          ));
      ref.read(sessionProvider.notifier).setUser(user);
      if (mounted) {
        showMessage(context, 'Details saved.');
        context.go('/profile');
      }
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionProvider).value?.user.email ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/profile')),
        title: const Text('Personal details'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: pagePadding,
          children: [
            if (_error != null) ...[
              ErrorNote(_error!.firstError, title: "We couldn't save your details."),
              const SizedBox(height: 16),
            ],
            LabeledField(label: 'First name', controller: _first, maxLength: 100, errorText: _error?.field('first_name')),
            const SizedBox(height: 16),
            LabeledField(label: 'Last name', controller: _last, maxLength: 100, errorText: _error?.field('last_name')),
            const SizedBox(height: 4),
            Text('Your name appears on your certificates.', style: context.text.bodySmall),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Email',
              controller: TextEditingController(text: email),
              readOnly: true,
              helper: 'Contact us to change the email you log in with.',
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Phone',
              controller: _phone,
              optional: true,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              errorText: _error?.field('phone'),
            ),
            const SizedBox(height: 16),
            LabeledField(label: 'Country', controller: _country, optional: true, maxLength: 100),
            const SizedBox(height: 16),
            LabeledField(label: 'State or city', controller: _city, optional: true, maxLength: 100),
            const SizedBox(height: 16),
            LabeledField(
              label: 'About you',
              controller: _bio,
              optional: true,
              maxLines: 4,
              maxLength: 1000,
              helper: 'Your role, background, or what you want to learn.',
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Save details', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(_current.text, _next.text);
      if (mounted) {
        showMessage(context, 'Password updated.');
        context.go('/profile');
      }
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final general = _error != null && _error!.field('old_password') == null && _error!.field('new_password') == null;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/profile')),
        title: const Text('Change password'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: pagePadding,
          children: [
            if (general) ...[ErrorNote(_error!.message), const SizedBox(height: 16)],
            LabeledField(
              label: 'Current password',
              controller: _current,
              obscure: true,
              autofillHints: const [AutofillHints.password],
              errorText: _error?.field('old_password'),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'New password',
              controller: _next,
              obscure: true,
              helper: 'At least 8 characters. Avoid common or all-number passwords.',
              autofillHints: const [AutofillHints.newPassword],
              validator: validateNewPassword,
              errorText: _error?.field('new_password'),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Confirm new password',
              controller: _confirm,
              obscure: true,
              validator: (v) => v != _next.text ? "The passwords don't match." : null,
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Update password', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
