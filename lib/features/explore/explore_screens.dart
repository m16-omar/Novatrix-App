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
import '../../data/models/site_catalog.dart';
import '../../data/site_content.dart';
import '../../data/repositories/catalog_repository.dart';
import '../public/site_sections.dart';

/* ---------- shared ---------- */

IconData offeringIcon(String slug) => switch (slug) {
      'software-development' => LucideIcons.code,
      'system-implementation' => LucideIcons.settings,
      'systems-integration' => LucideIcons.cable,
      'support-and-maintenance' => LucideIcons.headphones,
      'corporate-training' => LucideIcons.presentation,
      'youth-and-workforce-programs' => LucideIcons.users,
      'web-and-mobile-platforms' => LucideIcons.smartphone,
      'business-automation' => LucideIcons.workflow,
      'data-and-ai' => LucideIcons.chartColumn,
      'learning-platforms' => LucideIcons.graduationCap,
      'portals-and-dashboards' => LucideIcons.layoutDashboard,
      _ => LucideIcons.sparkles,
    };

IconData industryIcon(String slug) => switch (slug) {
      'education' => LucideIcons.school,
      'healthcare' => LucideIcons.heartPulse,
      'nonprofits' => LucideIcons.handHeart,
      'smes' => LucideIcons.store,
      'public-sector' => LucideIcons.landmark,
      'media-and-communications' => LucideIcons.radio,
      _ => LucideIcons.building2,
    };

/// In-app pages that match a website page of the same path.
const _inAppPaths = {'/services', '/industries', '/insights', '/about'};

/// Opens a website path ("/system-implementation", "/insights/...") on its page in the app when the app
/// has one, or on the website otherwise.
void openSitePath(BuildContext context, String path) {
  final catalog = ProviderScope.containerOf(context, listen: false).read(siteCatalogProvider).value;
  final offering = catalog?.offeringForPath(path);
  if (offering != null) {
    context.push('/services/${offering.slug}');
  } else if (path == '/technology-training' || path.startsWith('/courses')) {
    context.go(path.startsWith('/courses') ? path : '/courses');
  } else if (_inAppPaths.contains(path) || path.startsWith('/industries/') || path.startsWith('/insights/')) {
    context.push(path);
  } else {
    openLink(context, '${AppConfig.siteUrl}$path');
  }
}

/// Where an offering's call to action leads: a project inquiry, a support request, or a training inquiry.
void startOffering(BuildContext context, WidgetRef ref, Offering o) {
  switch (o.ctaForm) {
    case CtaForm.training:
      context.push('/training-inquiry?program=${o.slug}');
    case CtaForm.support:
      // Clients raise support tickets on their projects; anyone else sends a support inquiry.
      final roles = ref.read(sessionProvider).value?.roles;
      context.push(roles != null && roles.hasClientProjects
          ? '/client/support/new'
          : '/consultation?service=support_maintenance&about=${o.slug}');
    case CtaForm.project:
      context.push('/consultation?service=${o.ctaService ?? 'other'}&about=${o.slug}');
  }
}

/// Loads the bundled website content, then builds the page from it.
class _WithContent extends StatelessWidget {
  const _WithContent({required this.title, required this.builder});

  final String title;
  final Widget Function(SiteCatalog content) builder;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AsyncBody(provider: siteCatalogProvider, builder: builder),
      );
}

class _NotFound extends StatelessWidget {
  const _NotFound(this.what);
  final String what;

  @override
  Widget build(BuildContext context) => Padding(
        padding: pagePadding,
        child: EmptyState(
          icon: LucideIcons.searchX,
          title: "We couldn't find this $what.",
          action: SecondaryButton(label: 'Back to home', expand: false, onPressed: () => context.go('/')),
        ),
      );
}

/// The gradient header at the top of a detail page.
class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.eyebrow, required this.title, required this.intro});

  final IconData icon;
  final String eyebrow;
  final String title;
  final String intro;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: context.text.labelSmall?.copyWith(color: white, letterSpacing: 1.6, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: context.text.headlineSmall?.copyWith(color: white)),
          const SizedBox(height: 10),
          Text(intro, style: context.text.bodyMedium?.copyWith(color: white.withValues(alpha: 0.88), height: 1.45)),
        ],
      ),
    );
  }
}

/// A list of points with an icon in front of each.
class _Points extends StatelessWidget {
  const _Points(this.points, {this.icon = LucideIcons.circleCheck, this.color});

  final List<String> points;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final point in points)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 17, color: color ?? context.palette.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(point, style: context.text.bodyMedium?.copyWith(height: 1.4))),
                ],
              ),
            ),
        ],
      );
}

/// Titled items in one card, separated by lines.
class _ItemList extends StatelessWidget {
  const _ItemList(this.items, {this.icon = LucideIcons.check});

  final List<Item> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: p.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: p.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: context.text.labelLarge),
                        const SizedBox(height: 2),
                        Text(item.description, style: context.text.bodySmall?.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Numbered steps joined by a line: the delivery process.
class ProcessSteps extends StatelessWidget {
  const ProcessSteps(this.steps, {super.key});
  final List<Item> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        for (final (i, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(gradient: p.gradient, shape: BoxShape.circle),
                        child: Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: context.text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(child: Container(width: 2, color: p.brand.withValues(alpha: 0.2))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: i < steps.length - 1 ? 18 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(step.description, style: context.text.bodySmall?.copyWith(height: 1.4)),
                      ],
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

class _Faqs extends StatelessWidget {
  const _Faqs(this.faqs);
  final List<Faq> faqs;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          // No divider lines drawn by the tiles themselves; the card adds its own.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Column(
            children: [
              for (final (i, faq) in faqs.indexed) ...[
                if (i > 0) Divider(color: context.palette.border),
                ExpansionTile(
                  title: Text(faq.question, style: context.text.labelLarge),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(faq.answer, style: context.text.bodyMedium?.copyWith(height: 1.45))],
                ),
              ],
            ],
          ),
        ),
      );
}

/// The closing call to action on a page.
class _CtaCard extends StatelessWidget {
  const _CtaCard({required this.heading, required this.body, required this.label, required this.onPressed});

  final String heading;
  final String body;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: context.text.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(body, style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.88))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: p.brand,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: context.text.labelLarge,
              ),
              icon: const Icon(LucideIcons.arrowRight, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row linking to an offering: icon, name, summary.
class OfferingTile extends StatelessWidget {
  const OfferingTile({super.key, required this.offering});
  final Offering offering;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: () => context.push('/services/${offering.slug}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: p.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(offeringIcon(offering.slug), size: 20, color: p.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offering.name, style: context.text.labelLarge),
                const SizedBox(height: 3),
                Text(offering.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight, size: 18, color: p.mutedForeground),
        ],
      ),
    );
  }
}

/* ---------- services ---------- */

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) => _WithContent(
        title: 'Services',
        builder: (content) => ListView(
          padding: pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Services',
              title: 'We develop the solution, implement the system, train the users, and support long-term success.',
              intro: 'Use one service or connect them into a complete delivery lifecycle.',
            ),
            const SectionTitle('What we do'),
            for (final o in content.offerings) ...[OfferingTile(offering: o), const SizedBox(height: 10)],
            const SectionTitle('Training for organizations'),
            for (final o in content.programs) ...[OfferingTile(offering: o), const SizedBox(height: 10)],
            const SectionTitle('Solutions we build'),
            for (final o in content.solutions) ...[OfferingTile(offering: o), const SizedBox(height: 10)],
            const SectionTitle('One process across every service'),
            ProcessSteps(content.offerings.first.process),
            _CtaCard(
              heading: 'Tell us what you need.',
              body: "We'll help you choose the right starting point.",
              label: 'Request a consultation',
              onPressed: () => context.push('/consultation'),
            ),
          ],
        ),
      );
}

/// A service, training program, or solution.
class OfferingScreen extends ConsumerWidget {
  const OfferingScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final name = ref.watch(siteCatalogProvider).value?.offering(slug)?.name ?? '';
    return _WithContent(
      title: name,
      builder: (content) {
        final o = content.offering(slug);
        if (o == null) return const _NotFound('page');
        final industries = [for (final s in o.industries) ?content.industry(s)];
        return ListView(
          padding: pagePadding,
          children: [
            _Hero(icon: offeringIcon(o.slug), eyebrow: o.eyebrow, title: o.title, intro: o.intro),
            if (o.audience.isNotEmpty) ...[
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.users, size: 18, color: p.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "Who it's for: ", style: context.text.labelLarge),
                            TextSpan(text: o.audience),
                          ],
                        ),
                        style: context.text.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (o.problemHeading.isNotEmpty) ...[
              const SectionTitle('The challenge'),
              Text(o.problemHeading, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(o.problemBody, style: context.text.bodyMedium?.copyWith(color: p.mutedForeground, height: 1.45)),
              if (o.problemPoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sound familiar?', style: context.text.labelLarge),
                      const SizedBox(height: 4),
                      _Points(o.problemPoints, icon: LucideIcons.circleAlert, color: p.warning),
                    ],
                  ),
                ),
              ],
            ],
            if (o.capabilities.isNotEmpty) ...[
              const SectionTitle('What we deliver'),
              _ItemList(o.capabilities),
              if (o.boundaries.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(o.boundaries, style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ],
            if (o.engagementTypes.isNotEmpty) ...[
              const SectionTitle('Ways to work with us'),
              _ItemList(o.engagementTypes, icon: LucideIcons.handshake),
            ],
            if (o.process.isNotEmpty) ...[
              const SectionTitle('How we deliver'),
              ProcessSteps(o.process),
            ],
            if (industries.isNotEmpty) ...[
              const SectionTitle('Where this applies'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final i in industries) _IndustryChip(industry: i)],
              ),
            ],
            if (o.faqs.isNotEmpty) ...[
              const SectionTitle('Questions we are often asked'),
              _Faqs(o.faqs),
            ],
            _CtaCard(
              heading: o.ctaHeading.isEmpty ? 'Talk to us.' : o.ctaHeading,
              body: o.ctaBody,
              label: o.ctaLabel.isEmpty ? 'Request a consultation' : o.ctaLabel,
              onPressed: () => startOffering(context, ref, o),
            ),
          ],
        );
      },
    );
  }
}

/* ---------- industries ---------- */

class _IndustryChip extends StatelessWidget {
  const _IndustryChip({required this.industry});
  final Industry industry;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(industryIcon(industry.slug), size: 16, color: context.palette.brand),
        label: Text(industry.name),
        onPressed: () => context.push('/industries/${industry.slug}'),
      );
}

class IndustriesScreen extends StatelessWidget {
  const IndustriesScreen({super.key});

  @override
  Widget build(BuildContext context) => _WithContent(
        title: 'Industries',
        builder: (content) => ListView(
          padding: pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Industries',
              title: 'Solutions shaped by your sector.',
              intro: 'We work with organizations whose needs we understand, and confirm sector requirements during discovery.',
            ),
            const SizedBox(height: 20),
            for (final i in content.industries) ...[IndustryCard(industry: i), const SizedBox(height: 10)],
          ],
        ),
      );
}

class IndustryCard extends StatelessWidget {
  const IndustryCard({super.key, required this.industry});
  final Industry industry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: () => context.push('/industries/${industry.slug}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(12)),
            child: Icon(industryIcon(industry.slug), size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(industry.name, style: context.text.labelLarge),
                const SizedBox(height: 2),
                Text(industry.summary, style: context.text.bodySmall?.copyWith(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight, size: 18, color: p.mutedForeground),
        ],
      ),
    );
  }
}

class IndustryScreen extends ConsumerWidget {
  const IndustryScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(siteCatalogProvider).value?.industry(slug)?.name ?? '';
    return _WithContent(
      title: name,
      builder: (content) {
        final industry = content.industry(slug);
        if (industry == null) return const _NotFound('industry');
        final related = [for (final path in industry.servicePaths) ?content.offeringForPath(path)];
        return ListView(
          padding: pagePadding,
          children: [
            _Hero(icon: industryIcon(industry.slug), eyebrow: industry.name, title: industry.title, intro: industry.intro),
            if (industry.problems.isNotEmpty) ...[
              const SectionTitle('Common challenges'),
              AppCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: _Points(industry.problems, icon: LucideIcons.circleAlert, color: context.palette.warning),
              ),
            ],
            if (industry.sampleSolutions.isNotEmpty) ...[
              const SectionTitle('What we can do'),
              _ItemList(industry.sampleSolutions, icon: LucideIcons.lightbulb),
            ],
            if (related.isNotEmpty) ...[
              const SectionTitle('Related services'),
              for (final o in related) ...[OfferingTile(offering: o), const SizedBox(height: 10)],
            ],
            if (industry.training.isNotEmpty) ...[
              const SectionTitle('Training'),
              AppCard(
                onTap: () => context.go('/courses'),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(LucideIcons.graduationCap, color: context.palette.brand),
                    const SizedBox(width: 12),
                    Expanded(child: Text(industry.training, style: context.text.bodyMedium?.copyWith(height: 1.4))),
                  ],
                ),
              ),
            ],
            _CtaCard(
              heading: 'Working in ${industry.name.toLowerCase()}?',
              body: "Tell us about your organization and what you need. We'll share how we'd approach it.",
              label: 'Request a consultation',
              onPressed: () => context.push('/consultation?about=${industry.slug}'),
            ),
          ],
        );
      },
    );
  }
}

/* ---------- insights ---------- */

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) => _WithContent(
        title: 'Insights',
        builder: (content) => ListView(
          padding: pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Insights',
              title: 'Practical guidance from our team.',
              intro: 'Guides and articles on software, system implementation, and technology training.',
            ),
            const SizedBox(height: 20),
            for (final i in content.insights) ...[InsightCard(insight: i), const SizedBox(height: 12)],
          ],
        ),
      );
}

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => context.push('/insights/${insight.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pill(insight.category, tone: PillTone.brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatDate(insight.date)} · ${insight.readMinutes} min read',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(insight.title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(insight.summary, style: context.text.bodySmall?.copyWith(height: 1.4)),
          ],
        ),
      );
}

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) => _WithContent(
        title: 'Insights',
        builder: (content) {
          final insight = content.insight(slug);
          if (insight == null) return const _NotFound('article');
          final p = context.palette;
          final related = [for (final s in insight.related) ?content.insight(s)];
          return ListView(
            padding: pagePadding,
            children: [
              Row(
                children: [
                  Pill(insight.category, tone: PillTone.brand),
                  const SizedBox(width: 8),
                  Text('${insight.readMinutes} min read', style: context.text.bodySmall),
                ],
              ),
              const SizedBox(height: 14),
              Text(insight.title, style: context.text.headlineSmall),
              const SizedBox(height: 10),
              Text(
                '${insight.author} · ${formatDate(insight.date)}',
                style: context.text.bodySmall?.copyWith(color: p.mutedForeground),
              ),
              const SizedBox(height: 16),
              Text(insight.summary, style: context.text.bodyLarge?.copyWith(color: p.mutedForeground, height: 1.5)),
              const SizedBox(height: 8),
              const Divider(height: 24),
              for (final block in insight.body)
                switch (block.type) {
                  BlockType.heading => Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 6),
                      child: Text(block.text, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  BlockType.paragraph => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(block.text, style: context.text.bodyLarge?.copyWith(height: 1.55)),
                    ),
                  BlockType.bullets => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _Points(block.items, icon: LucideIcons.dot),
                    ),
                },
              if (insight.ctaLabel.isNotEmpty)
                _CtaCard(
                  heading: 'Ready for the next step?',
                  body: 'Talk with Novatrix about what this means for your organization.',
                  label: insight.ctaLabel,
                  onPressed: () => openSitePath(context, insight.ctaPath),
                ),
              if (related.isNotEmpty) ...[
                const SectionTitle('Keep reading'),
                for (final r in related) ...[InsightCard(insight: r), const SizedBox(height: 12)],
              ],
            ],
          );
        },
      );
}

/* ---------- about ---------- */

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _WithContent(
      title: 'About Novatrix',
      builder: (content) => ListView(
        padding: pagePadding,
        children: [
          const _Hero(
            icon: LucideIcons.sparkles,
            eyebrow: 'About us',
            title: SiteContent.aboutTitle,
            intro: SiteContent.aboutIntro,
          ),
          const SizedBox(height: 14),
          for (final (icon, label, text) in [
            (LucideIcons.target, 'Our mission', SiteContent.mission),
            (LucideIcons.eye, 'Our vision', SiteContent.vision),
          ]) ...[
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: p.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: context.text.labelLarge),
                        const SizedBox(height: 4),
                        Text(text, style: context.text.bodyMedium?.copyWith(height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SiteSectionHeader(eyebrow: 'Why we exist', title: SiteContent.existTitle, intro: SiteContent.existText),
          for (final (i, (title, text)) in SiteContent.pillars.indexed) ...[
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => p.gradient.createShader(r),
                    child: Text('0${i + 1}', style: context.text.titleLarge?.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(text, style: context.text.bodySmall?.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SiteSectionHeader(eyebrow: 'Our values', title: 'What guides our work.'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (final (title, text) in SiteContent.values)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.heart, size: 18, color: p.brand),
                      const Spacer(),
                      Text(title, style: context.text.labelLarge),
                      const SizedBox(height: 2),
                      Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
          const SiteSectionHeader(
            eyebrow: 'How we deliver',
            title: SiteContent.deliveryTitle,
            intro: SiteContent.deliveryIntro,
          ),
          ProcessSteps(content.offerings.first.process),
          const ImpactSection(),
          const SiteSectionHeader(eyebrow: 'Responsible technology', title: 'Our commitments.'),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, color: p.brand),
                const SizedBox(width: 12),
                Expanded(child: Text(SiteContent.commitments, style: context.text.bodyMedium?.copyWith(height: 1.45))),
              ],
            ),
          ),
          const SiteSectionHeader(eyebrow: 'Contact', title: "Let's talk."),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.mail),
                  title: const Text(AppConfig.supportEmail),
                  trailing: const Icon(LucideIcons.externalLink, size: 16),
                  onTap: () => openLink(context, 'mailto:${AppConfig.supportEmail}'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.globe),
                  title: Text(Uri.parse(AppConfig.siteUrl).host),
                  trailing: const Icon(LucideIcons.externalLink, size: 16),
                  onTap: () => openLink(context, AppConfig.siteUrl),
                ),
                const Divider(),
                const ListTile(leading: Icon(LucideIcons.mapPin), title: Text(SiteContent.location)),
              ],
            ),
          ),
          const TalkToUsPanel(),
        ],
      ),
    );
  }
}

/* ---------- training inquiry ---------- */

/// Corporate training and workforce program requests, sent like the website's training inquiry form.
class TrainingInquiryScreen extends ConsumerStatefulWidget {
  const TrainingInquiryScreen({super.key, this.program, this.topic, this.forOrganization = true});

  /// The program the request came from, to set the topic.
  final String? program;

  /// A topic to start with, such as a course title.
  final String? topic;

  /// Whether the form starts on "My organization" rather than "Myself".
  final bool forOrganization;

  @override
  ConsumerState<TrainingInquiryScreen> createState() => _TrainingInquiryScreenState();
}

class _TrainingInquiryScreenState extends ConsumerState<TrainingInquiryScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _organization = TextEditingController();
  final _participants = TextEditingController();
  final _topic = TextEditingController();
  final _outcome = TextEditingController();
  late bool _forOrganization = widget.forOrganization;
  String? _format;
  bool _busy = false;
  bool _sent = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).value?.user;
    _name.text = user?.fullName ?? '';
    _email.text = user?.email ?? '';
    _topic.text = widget.topic ?? '';
    ref.read(siteCatalogProvider.future).then((content) {
      final program = widget.program == null ? null : content.offering(widget.program!);
      if (program != null && mounted && _topic.text.isEmpty) _topic.text = program.name;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _organization, _participants, _topic, _outcome]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(catalogRepositoryProvider).requestTraining(
            forOrganization: _forOrganization,
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            organization: _organization.text,
            participants: int.tryParse(_participants.text.trim()) ?? 1,
            topic: _topic.text,
            outcome: _outcome.text,
            format: _format,
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
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Training request')),
      body: ListView(
        padding: pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Technology training',
            title: 'Request a training proposal',
            intro: 'Tell us about your audience, objectives, participant numbers, and preferred format.',
          ),
          const SizedBox(height: 20),
          if (_sent)
            EmptyState(
              icon: LucideIcons.circleCheck,
              title: 'Thank you. Your request is in.',
              message: "We've emailed you a confirmation and will follow up with next steps.",
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
                    Text('Who is the training for?', style: context.text.labelLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: p.brand,
                          selectedForegroundColor: Colors.white,
                          side: BorderSide(color: p.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        segments: const [
                          ButtonSegment(value: true, label: Text('My organization')),
                          ButtonSegment(value: false, label: Text('Myself')),
                        ],
                        selected: {_forOrganization},
                        onSelectionChanged: (s) => setState(() => _forOrganization = s.first),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      errorText: _error?.field('phone_or_whatsapp'),
                    ),
                    if (_forOrganization) ...[
                      const SizedBox(height: 16),
                      LabeledField(label: 'Organization', controller: _organization, errorText: _error?.field('organization')),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Number of participants',
                        controller: _participants,
                        keyboardType: TextInputType.number,
                        validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1 ? 'Enter the number of participants.' : null,
                        errorText: _error?.field('participant_count'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Training topic',
                      controller: _topic,
                      maxLength: 200,
                      hint: 'For example: data analytics for our finance team',
                      errorText: _error?.field('training_topic_custom'),
                    ),
                    const SizedBox(height: 16),
                    LabeledDropdown<String>(
                      label: 'Preferred format',
                      optional: true,
                      value: _format,
                      hint: 'Choose a format',
                      items: trainingFormats,
                      onChanged: (v) => setState(() => _format = v),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Desired outcome',
                      controller: _outcome,
                      maxLines: 5,
                      maxLength: 2000,
                      helper: 'What should participants be able to do after the training?',
                      errorText: _error?.field('desired_outcome'),
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
