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
import '../../data/models/course.dart';
import '../../data/models/learning.dart';
import '../../data/repositories/catalog_repository.dart';
import '../shell/app_shell.dart';
import '../shell/workspace.dart';

const _services = [
  (LucideIcons.code, 'Software Development', 'Web, mobile, portals and automation', 'software-development'),
  (LucideIcons.rocket, 'System Implementation', 'From assessment to go-live', 'system-implementation'),
  (LucideIcons.layers, 'Systems Integration', 'Connect applications and data', 'systems-integration'),
  (LucideIcons.wrench, 'Support and Maintenance', 'Keep systems healthy and improving', 'support-and-maintenance'),
];

/* ---------- home ---------- */

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final p = context.palette;
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.public),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(coursesProvider.future),
        child: ListView(
          padding: pagePadding,
          children: [
            const SizedBox(height: 8),
            const Eyebrow('Build. Implement. Empower.'),
            const SizedBox(height: 10),
            Text(
              'Software that works. Systems that scale. Training that lasts.',
              style: context.text.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Novatrix designs software, implements digital systems, and trains people to use technology effectively.',
              style: context.text.bodyLarge?.copyWith(color: p.mutedForeground),
            ),
            const SizedBox(height: 24),
            if (session != null)
              GradientButton(
                label: 'Go to my dashboard',
                icon: LucideIcons.layoutDashboard,
                onPressed: () => context.go(Workspace.primaryFor(session.roles).home),
              )
            else
              GradientButton(
                label: 'Explore courses',
                icon: LucideIcons.graduationCap,
                onPressed: () => context.go('/courses'),
              ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Request a consultation',
              icon: LucideIcons.messageSquarePlus,
              onPressed: () => context.go('/consultation'),
            ),
            SectionTitle('Featured courses', action: 'All courses', onAction: () => context.go('/courses')),
            SizedBox(
              height: 290,
              child: AsyncBody(
                provider: coursesProvider,
                loadingLabel: 'Loading courses…',
                builder: (courses) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length.clamp(0, 6),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(width: 260, child: CourseCard(course: courses[i])),
                ),
              ),
            ),
            const SectionTitle('What we do'),
            for (final (icon, title, description, path) in _services) ...[
              AppCard(
                onTap: () => openLink(context, '${AppConfig.siteUrl}/$path'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.titleMedium),
                          Text(description, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.externalLink, size: 16, color: p.mutedForeground),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SectionTitle('More'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.award),
                    title: const Text('Verify a certificate'),
                    trailing: const Icon(LucideIcons.externalLink, size: 16),
                    onTap: () => openLink(context, '${AppConfig.siteUrl}/certificates'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(LucideIcons.briefcase),
                    title: const Text('Client login'),
                    subtitle: const Text('Projects, documents, and support'),
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    onTap: () => context.go(session == null ? '/login?as=client' : '/client'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(LucideIcons.mail),
                    title: const Text(AppConfig.supportEmail),
                    onTap: () => openLink(context, 'mailto:${AppConfig.supportEmail}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- catalog ---------- */

class CourseImage extends StatelessWidget {
  const CourseImage({super.key, required this.course, this.height = 140});

  final Course course;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = Container(
      height: height,
      decoration: BoxDecoration(gradient: p.gradient),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 40),
    );
    final url = course.coverImageUrl;
    final asset = course.bundledImage;
    final Widget image = url != null
        ? Image.network(url, height: height, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback)
        : asset != null
            ? Image.asset(asset, height: height, width: double.infinity, fit: BoxFit.cover)
            : fallback;
    return ExcludeSemantics(child: image);
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.go('/courses/${course.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseImage(course: course, height: 120),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.topic, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  Text(course.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                  const SizedBox(height: 6),
                  Text(course.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(formatMoney(course.price, course.currency), style: context.text.titleMedium),
                      const Spacer(),
                      Text('${course.durationWeeks} weeks · ${course.levelShort}', style: context.text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  String _query = '';
  String? _topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.public),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(coursesProvider.future),
        child: ListView(
          padding: pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Training',
              title: 'Courses',
              intro: 'Live, cohort-based courses with hands-on projects and a certificate of completion.',
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search courses',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            AsyncBody(
              provider: coursesProvider,
              loadingLabel: 'Loading courses…',
              builder: (courses) {
                final topics = {for (final c in courses) c.topic}.where((t) => t.isNotEmpty).toList()..sort();
                final shown = courses
                    .where((c) => _topic == null || c.topic == _topic)
                    .where((c) => _query.isEmpty ||
                        c.title.toLowerCase().contains(_query) ||
                        c.summary.toLowerCase().contains(_query))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final t in [null, ...topics])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(t ?? 'All'),
                                selected: _topic == t,
                                onSelected: (_) => setState(() => _topic = t),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (shown.isEmpty)
                      const EmptyState(icon: LucideIcons.search, title: 'No courses match your search.')
                    else
                      for (final c in shown) ...[CourseCard(course: c), const SizedBox(height: 12)],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final enrolled = session == null
        ? false
        : (ref.watch(enrollmentsProvider).value ?? const <Enrollment>[])
            .any((e) => e.course.slug == slug && e.status != 'cancelled');

    return Scaffold(
      appBar: AppBar(title: const Text('Course')),
      body: AsyncBody(
        provider: courseProvider(slug),
        loadingLabel: 'Loading course…',
        builder: (course) => ListView(
          padding: EdgeInsets.zero,
          children: [
            CourseImage(course: course, height: 200),
            Padding(
              padding: pagePadding.copyWith(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(course.topic),
                  const SizedBox(height: 8),
                  Text(course.title, style: context.text.headlineMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(course.levelShort),
                      Pill('${course.durationWeeks} weeks'),
                      if (course.format.isNotEmpty) Pill(course.format),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(course.summary, style: context.text.bodyLarge),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatMoney(course.price, course.currency), style: context.text.headlineSmall),
                        const SizedBox(height: 12),
                        if (enrolled)
                          GradientButton(
                            label: 'Continue course',
                            icon: LucideIcons.circlePlay,
                            onPressed: () => context.go('/learn/course/$slug'),
                          )
                        else ...[
                          GradientButton(
                            label: 'Enroll on the website',
                            icon: LucideIcons.externalLink,
                            onPressed: () => openLink(context, '${AppConfig.siteUrl}/courses/$slug'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enrollment and payment happen securely on thenovatrix.com. Your course then appears here.',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (course.audience.isNotEmpty) ...[
                    const SectionTitle("Who it's for"),
                    Text(course.audience),
                  ],
                  if (course.outcomes.isNotEmpty) ...[
                    const SectionTitle("What you'll learn"),
                    _CheckList(course.outcomes),
                  ],
                  if (course.projects.isNotEmpty) ...[
                    const SectionTitle("What you'll build"),
                    _CheckList(course.projects),
                  ],
                  if (course.prerequisites.isNotEmpty) ...[
                    const SectionTitle('Before you start'),
                    Text(course.prerequisites),
                  ],
                  if (course.cohorts.isNotEmpty) ...[
                    const SectionTitle('Upcoming cohorts'),
                    for (final c in course.cohorts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.calendar),
                        title: Text(c.name),
                        subtitle: Text('${formatDate(c.startDate)} – ${formatDate(c.endDate)}'
                            '${c.schedule.isNotEmpty ? '\n${c.schedule}' : ''}'),
                      ),
                  ],
                  _Syllabus(slug: slug),
                  if (course.certificate.isNotEmpty) ...[
                    const SectionTitle('Certificate'),
                    Text(course.certificate),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckList extends StatelessWidget {
  const _CheckList(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.circleCheck, size: 18, color: context.palette.brand),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      );
}

class _Syllabus extends ConsumerWidget {
  const _Syllabus({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(curriculumProvider(slug)).value ?? const <ModuleOutline>[];
    if (modules.isEmpty) return const SizedBox.shrink();
    final lessons = modules.fold<int>(0, (n, m) => n + m.lessons.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle("What's inside (${plural(lessons, 'lesson')})"),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final m in modules)
                ExpansionTile(
                  shape: const Border(),
                  title: Text(m.title, style: context.text.titleMedium),
                  subtitle: Text(plural(m.lessons.length, 'lesson'), style: context.text.bodySmall),
                  children: [
                    for (final l in m.lessons)
                      ListTile(
                        dense: true,
                        leading: Icon(_kindIcon(l.kind), size: 18),
                        title: Text(l.title),
                        trailing: l.isPreview ? const Pill('Free preview', tone: PillTone.brand) : null,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _kindIcon(LessonKind kind) => switch (kind) {
      LessonKind.video => LucideIcons.video,
      LessonKind.assignment => LucideIcons.clipboardCheck,
      LessonKind.live => LucideIcons.presentation,
      LessonKind.reading => LucideIcons.fileText,
    };

/* ---------- consultation ---------- */

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({super.key});

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _email = TextEditingController();
  final _phone = TextEditingController();
  final _organization = TextEditingController();
  final _description = TextEditingController();
  String? _service;
  String? _timeline;
  bool _busy = false;
  bool _sent = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).value?.user;
    _name.text = user == null ? '' : user.fullName;
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _organization, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(catalogRepositoryProvider).requestConsultation(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            organization: _organization.text,
            service: _service!,
            timeline: _timeline!,
            description: _description.text,
          );
      setState(() => _sent = true);
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WorkspaceAppBar(workspace: Workspace.public),
      body: ListView(
        padding: pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Work with us',
            title: 'Request a consultation',
            intro: 'Tell us about your project. We reply within two business days.',
          ),
          const SizedBox(height: 20),
          if (_sent)
            EmptyState(
              icon: LucideIcons.circleCheck,
              title: 'Thank you. Your request is in.',
              message: "We've emailed you a confirmation and will be in touch within two business days.",
              action: SecondaryButton(label: 'Back to home', expand: false, onPressed: () => context.go('/')),
            )
          else
            Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      ErrorNote(_error!.firstError, title: "We couldn't send your request."),
                      const SizedBox(height: 16),
                    ],
                    LabeledField(label: 'Name', controller: _name, autofillHints: const [AutofillHints.name]),
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
                      label: 'Phone or WhatsApp',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: 16),
                    LabeledField(label: 'Organization', controller: _organization, optional: true),
                    const SizedBox(height: 16),
                    LabeledDropdown<String>(
                      label: 'Service required',
                      value: _service,
                      hint: 'Choose a service',
                      items: consultationServices,
                      onChanged: (v) => setState(() => _service = v),
                    ),
                    const SizedBox(height: 16),
                    LabeledDropdown<String>(
                      label: 'Desired timeline',
                      value: _timeline,
                      hint: 'Choose a timeline',
                      items: consultationTimelines,
                      onChanged: (v) => setState(() => _timeline = v),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Project description',
                      controller: _description,
                      maxLines: 5,
                      maxLength: 5000,
                      helper: 'What do you want to build or improve, and for whom?',
                    ),
                    const SizedBox(height: 8),
                    ConsentField(
                      text: 'I agree that The Novatrix may use these details to respond to my request, '
                          'as described in the Privacy Policy.',
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Send request', icon: LucideIcons.send, busy: _busy, onPressed: _submit),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
