import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_config.dart';
import '../../core/cart.dart';
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
import '../../data/site_content.dart';
import '../notifications/notifications_screen.dart';
import '../shell/app_shell.dart';
import '../shell/workspace.dart';
import 'site_sections.dart';

/* ---------- home ---------- */

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(coursesProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session == null ? '${greeting()} 👋' : '${greeting()}, ${session.user.firstName} 👋',
                          style: context.text.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text('What would you like to do today?', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                  const CartButton(),
                  if (session != null)
                    IconButton(
                      tooltip: 'My dashboard',
                      onPressed: () => context.go(Workspace.primaryFor(session.roles).home),
                      icon: Avatar(user: session.user, size: 40),
                    )
                  else
                    IconButton.outlined(
                      tooltip: 'Log in',
                      style: IconButton.styleFrom(side: BorderSide(color: p.border)),
                      onPressed: () => context.go('/login'),
                      icon: Icon(LucideIcons.circleUserRound, color: p.foreground),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Semantics(
                button: true,
                label: 'Search courses',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go('/courses'),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: p.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search, size: 18, color: p.mutedForeground),
                        const SizedBox(width: 12),
                        Text('What are you looking for?', style: context.text.bodyMedium?.copyWith(color: p.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const AnnouncementCard(),
              const SizedBox(height: 14),
              const _HeroBanner(),
              const ServicesSection(),
              const WhyNovatrixCard(),
              SiteSectionHeader(
                eyebrow: 'Technology training',
                title: 'Practical skills for individuals and teams.',
                intro: 'Live, cohort-based, project-driven courses — and customized programs for organizations.',
                action: 'All courses',
                onAction: () => context.go('/courses'),
              ),
              AsyncBody(
                provider: coursesProvider,
                loadingLabel: 'Loading courses…',
                builder: (courses) => courses.isEmpty
                    ? const EmptyState(icon: LucideIcons.graduationCap, title: 'New courses are coming soon.')
                    : Column(
                        children: [
                          for (final c in courses.take(4)) ...[_CourseRow(course: c), const SizedBox(height: 10)],
                        ],
                      ),
              ),
              const ImpactSection(),
              const IndustriesSection(),
              const TestimonialsSection(),
              const InsightsSection(),
              const TalkToUsPanel(),
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
      ),
    );
  }
}

/// The website's hero, as a banner at the top of the home screen.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          // Layered shapes in the corner, echoing the logo's connected nodes.
          Positioned(
            right: -26,
            top: -18,
            child: ExcludeSemantics(
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final (dx, dy, size, alpha) in const [
                      (18.0, -18.0, 54.0, 0.18),
                      (-12.0, 14.0, 64.0, 0.26),
                      (26.0, 40.0, 34.0, 0.85),
                    ])
                      Transform.translate(
                        offset: Offset(dx, dy),
                        child: Transform.rotate(
                          angle: 0.78,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: alpha),
                              borderRadius: BorderRadius.circular(size * 0.22),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SiteContent.heroEyebrow.toUpperCase(),
                  style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85), letterSpacing: 1.4, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(SiteContent.heroTitle, style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                Text(
                  SiteContent.heroTitleAccent,
                  style: context.text.headlineSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 10),
                Text(
                  SiteContent.heroIntro,
                  style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.45),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.go('/consultation'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Start a Project', style: context.text.labelLarge?.copyWith(color: p.brand)),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.chevronRight, size: 16, color: p.brand),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/courses'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Explore Our Training'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact course row for lists: thumbnail, title, length and level.
class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => context.go('/courses/${course.slug}'),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(dimension: 56, child: CourseImage(course: course, height: 56, compact: true)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    [if (course.durationWeeks > 0) '${course.durationWeeks} weeks', if (course.levelShort.isNotEmpty) course.levelShort].join(' · '),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Text(course.priceLabel, style: context.text.labelLarge?.copyWith(color: course.isFree ? context.palette.success : null)),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 18, color: context.palette.mutedForeground),
          ],
        ),
      );
}

/* ---------- catalog ---------- */

class CourseImage extends StatelessWidget {
  const CourseImage({super.key, required this.course, this.height = 140, this.compact = false});

  final Course course;
  final double height;

  /// For thumbnails: the fallback artwork leaves out the course title.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Courses without a cover get artwork in brand colours, varied per course so a list doesn't repeat itself.
    final variants = [
      [p.brand, p.brand2],
      [const Color(0xFF4F46E5), p.brand],
      [p.brand2, const Color(0xFFF97316)],
      [const Color(0xFF0EA5E9), p.brand],
    ];
    final colors = variants[course.slug.hashCode.abs() % variants.length];
    final fallback = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -height * 0.18,
            bottom: -height * 0.28,
            child: Icon(LucideIcons.graduationCap, color: Colors.white.withValues(alpha: 0.16), size: height * 1.1),
          ),
          if (!compact) Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
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

class CourseCard extends ConsumerWidget {
  const CourseCard({super.key, required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.go('/courses/${course.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CourseImage(course: course, height: 132),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      course.levelShort,
                      style: context.text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                      Text(course.priceLabel, style: context.text.titleLarge?.copyWith(color: course.isFree ? context.palette.success : null)),
                      const Spacer(),
                      Icon(LucideIcons.clock, size: 14, color: context.palette.mutedForeground),
                      const SizedBox(width: 4),
                      Text('${course.durationWeeks} weeks', style: context.text.bodySmall),
                      const SizedBox(width: 6),
                      if (course.isFree)
                        const SizedBox.shrink()
                      else if (ref.watch(cartProvider).contains(course.slug))
                        IconButton.filledTonal(
                          tooltip: '${course.title} is in your cart',
                          onPressed: () => context.push('/cart'),
                          icon: const Icon(LucideIcons.shoppingCart, size: 18),
                        )
                      else
                        IconButton.outlined(
                          tooltip: 'Add ${course.title} to cart',
                          onPressed: () => addToCart(context, ref, course),
                          icon: const Icon(LucideIcons.plus, size: 18),
                        ),
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
      appBar: const WorkspaceAppBar(workspace: Workspace.public, actions: [CartButton()]),
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
                    const WhyTrainSection(),
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
      appBar: AppBar(title: const Text('Course'), actions: const [CartButton(), SizedBox(width: 8)]),
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
                        Text(course.priceLabel, style: context.text.headlineSmall?.copyWith(color: course.isFree ? context.palette.success : null)),
                        const SizedBox(height: 12),
                        if (enrolled)
                          GradientButton(
                            label: 'Continue course',
                            icon: LucideIcons.circlePlay,
                            onPressed: () => context.go('/learn/course/$slug'),
                          )
                        else if (course.isFree) ...[
                          _EnrollFreeButton(course: course),
                          const SizedBox(height: 8),
                          Text(
                            'This course is free. Enroll and start learning straight away.',
                            style: context.text.bodySmall,
                          ),
                        ] else if (ref.watch(cartProvider).contains(slug)) ...[
                          GradientButton(
                            key: const ValueKey('view-cart'),
                            label: 'In your cart · View cart',
                            icon: LucideIcons.shoppingCart,
                            onPressed: () => context.push('/cart'),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: () => ref.read(cartProvider.notifier).remove(slug),
                              child: const Text('Remove from cart'),
                            ),
                          ),
                        ] else ...[
                          GradientButton(
                            key: const ValueKey('add-to-cart'),
                            label: 'Add to cart',
                            icon: LucideIcons.shoppingCart,
                            onPressed: () => addToCart(context, ref, course),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConfig.allowsWebCheckout
                                ? 'Check out from your cart. Your course then appears in My learning.'
                                : "Add courses you're interested in, then ask us about enrolling from your cart.",
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
  const ConsultationScreen({super.key, this.service, this.about});

  /// The service to preselect (a [consultationServices] value).
  final String? service;

  /// The service, solution, or industry page the request came from, to word the header.
  final String? about;

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
  late String? _service = consultationServices.any((s) => s.$1 == widget.service) ? widget.service : null;
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
    final content = ref.watch(siteCatalogProvider).value;
    final offering = widget.about == null ? null : content?.offering(widget.about!);
    final industry = widget.about == null ? null : content?.industry(widget.about!);
    return Scaffold(
      appBar: widget.about == null && widget.service == null
          ? const WorkspaceAppBar(workspace: Workspace.public)
          : AppBar(title: const Text('Consultation')),
      body: ListView(
        padding: pagePadding,
        children: [
          PageHeader(
            eyebrow: offering?.name ?? industry?.name ?? 'Work with us',
            title: offering?.ctaHeading ?? 'Request a consultation',
            intro: offering?.ctaBody ?? 'Tell us about your project. We reply within two business days.',
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

/// Adds a course to the cart and offers a way to see it.
void addToCart(BuildContext context, WidgetRef ref, Course course) {
  ref.read(cartProvider.notifier).add(course.slug);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('${course.title} is in your cart.'),
      action: SnackBarAction(label: 'View cart', onPressed: () => context.push('/cart')),
    ));
}

/// The cart icon for headers, with how many courses are in it.
class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider).length;
    return IconButton(
      key: const ValueKey('cart-button'),
      tooltip: count == 0 ? 'Cart' : 'Cart, ${plural(count, 'course')}',
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: context.palette.brand2,
        child: Icon(LucideIcons.shoppingCart, color: context.palette.foreground),
      ),
    );
  }
}

/// Enrolls in a free course in one tap: no cart, no payment.
class _EnrollFreeButton extends ConsumerStatefulWidget {
  const _EnrollFreeButton({required this.course});
  final Course course;

  @override
  ConsumerState<_EnrollFreeButton> createState() => _EnrollFreeButtonState();
}

class _EnrollFreeButtonState extends ConsumerState<_EnrollFreeButton> {
  bool _busy = false;

  Future<void> _enroll() async {
    final course = widget.course;
    final here = '/courses/${course.slug}';
    if (ref.read(sessionProvider).value == null) {
      context.go('/login?from=${Uri.encodeComponent(here)}');
      return;
    }
    setState(() => _busy = true);
    try {
      // A free course checks out at nothing: the backend enrolls without a payment provider.
      await ref.read(learningRepositoryProvider).startCheckout([course.slug]);
      await ref.read(cartProvider.notifier).remove(course.slug);
      ref.invalidate(enrollmentsProvider);
      ref.invalidate(ordersProvider);
      await ref.read(sessionProvider.notifier).refreshRoles();
      if (mounted) context.go('/learn/course/${course.slug}');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'email_not_verified') {
        context.go('/verify-email?send=1&from=${Uri.encodeComponent(here)}');
      } else {
        showMessage(context, e.firstError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => GradientButton(
        key: const ValueKey('enroll-free'),
        label: 'Enroll for free',
        icon: LucideIcons.graduationCap,
        busy: _busy,
        onPressed: _enroll,
      );
}
