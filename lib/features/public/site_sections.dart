import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/site_content.dart';
import '../explore/explore_screens.dart';

/// Website sections shown in the app: services, impact, industries, testimonials, and insights.
/// The home page copy lives in SiteContent; industries and insights come from the synced SiteCatalog.
/// Links open the matching page in the app (see openSitePath).

/// A section heading with the website's small gradient label above it.
class SiteSectionHeader extends StatelessWidget {
  const SiteSectionHeader({super.key, required this.eyebrow, required this.title, this.intro, this.action, this.onAction});

  final String eyebrow;
  final String title;
  final String? intro;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Eyebrow(eyebrow)),
                if (action != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text(action!), const SizedBox(width: 4), const Icon(LucideIcons.arrowRight, size: 16)],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: context.text.titleLarge),
            if (intro != null) ...[
              const SizedBox(height: 6),
              Text(intro!, style: context.text.bodySmall?.copyWith(height: 1.45)),
            ],
          ],
        ),
      );
}

/// "New cohort starts soon", like the website's announcement bar.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.brand.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/courses'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: p.brand),
              const SizedBox(width: 10),
              Expanded(child: Text(SiteContent.announcement, style: context.text.bodySmall?.copyWith(color: p.foreground))),
              const SizedBox(width: 8),
              Text('Enroll now', style: context.text.labelLarge?.copyWith(color: p.brand)),
              Icon(LucideIcons.chevronRight, size: 16, color: p.brand),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four services, with what each covers and a link to its page on the website.
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteSectionHeader(
          eyebrow: 'What we do',
          title: SiteContent.servicesTitle,
          intro: SiteContent.servicesIntro,
          action: 'All',
          onAction: () => context.push('/services'),
        ),
        for (final (i, s) in SiteContent.services.indexed) ...[
          AppCard(
            onTap: () => openSitePath(context, s.path),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(12)),
                  child: Icon(s.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('0${i + 1}', style: context.text.labelSmall?.copyWith(color: p.mutedForeground, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(s.title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(s.description, style: context.text.bodySmall?.copyWith(height: 1.45)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(child: Text(s.action, style: context.text.labelLarge?.copyWith(color: p.brand))),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.arrowRight, size: 15, color: p.brand),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// "Why Novatrix" in brief, opening the About screen.
class WhyNovatrixCard extends StatelessWidget {
  const WhyNovatrixCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: () => context.push('/about'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Why Novatrix'),
          const SizedBox(height: 6),
          Text(SiteContent.whyTitle, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final (title, _) in SiteContent.pillars)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(LucideIcons.circleCheck, size: 16, color: p.brand),
                  const SizedBox(width: 8),
                  Text(title, style: context.text.bodyMedium),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('How we work', style: context.text.labelLarge?.copyWith(color: p.brand)),
              const SizedBox(width: 4),
              Icon(LucideIcons.arrowRight, size: 15, color: p.brand),
            ],
          ),
        ],
      ),
    );
  }
}

/// The three headline numbers.
class ImpactSection extends StatelessWidget {
  const ImpactSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SiteSectionHeader(eyebrow: 'Our impact', title: SiteContent.impactTitle, intro: SiteContent.impactIntro),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (value, label)) in SiteContent.impact.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => context.palette.gradient.createShader(r),
                          child: Text(value, style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        Text(label, style: context.text.bodySmall?.copyWith(height: 1.3)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
}

/// The sectors Novatrix works with, scrolling sideways.
class IndustriesSection extends ConsumerWidget {
  const IndustriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final industries = ref.watch(siteCatalogProvider).value?.industries ?? const [];
    if (industries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteSectionHeader(
          eyebrow: 'Industries',
          title: SiteContent.industriesTitle,
          intro: SiteContent.industriesIntro,
          action: 'All',
          onAction: () => context.push('/industries'),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: industries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final industry = industries[i];
              return SizedBox(
                width: 210,
                child: AppCard(
                  onTap: () => context.push('/industries/${industry.slug}'),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(industryIcon(industry.slug), size: 22, color: p.brand),
                      const SizedBox(height: 10),
                      Text(industry.name, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          industry.summary,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Learner quotes, scrolling sideways.
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SiteSectionHeader(eyebrow: 'Testimonials', title: SiteContent.testimonialsTitle),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: SiteContent.testimonials.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final (quote, name, role) = SiteContent.testimonials[i];
              final initials = name.split(' ').map((w) => w[0]).take(2).join();
              return SizedBox(
                width: 260,
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.quote, size: 18, color: p.brand),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(quote, maxLines: 4, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium?.copyWith(height: 1.4)),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(gradient: p.gradient, shape: BoxShape.circle),
                            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: context.text.labelLarge),
                                Text(role, style: context.text.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The latest articles from the website.
class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final insights = ref.watch(siteCatalogProvider).value?.insights ?? const [];
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteSectionHeader(
          eyebrow: 'Insights',
          title: SiteContent.insightsTitle,
          action: 'All',
          onAction: () => context.push('/insights'),
        ),
        for (final insight in insights.take(3)) ...[
          AppCard(
            onTap: () => context.push('/insights/${insight.slug}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${insight.category} · ${formatDate(insight.date)} · ${insight.readMinutes} min read',
                  style: context.text.labelSmall?.copyWith(color: p.brand, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(insight.title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(insight.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// The closing "Let's talk about your next step" panel.
class TalkToUsPanel extends StatelessWidget {
  const TalkToUsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(gradient: p.gradient, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(SiteContent.ctaTitle, style: context.text.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(SiteContent.ctaText, style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.45)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/consultation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: p.brand,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start a Project'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/courses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text('Our Training'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Why train with The Novatrix", for the Courses screen.
class WhyTrainSection extends StatelessWidget {
  const WhyTrainSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SiteSectionHeader(eyebrow: 'Why train with The Novatrix', title: SiteContent.trainingTitle),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (icon, title, text) in SiteContent.trainingReasons)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: p.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, size: 17, color: p.brand),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: context.text.labelLarge),
                            const SizedBox(height: 2),
                            Text(text, style: context.text.bodySmall?.copyWith(height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text('Tools you will use', style: context.text.labelMedium?.copyWith(color: p.mutedForeground)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final t in SiteContent.tools) Pill(t)]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          onTap: () => openSitePath(context, '/corporate-training'),
          child: Row(
            children: [
              Icon(LucideIcons.building2, color: p.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Corporate training', style: context.text.labelLarge),
                    Text('Customized programs for organizations.', style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: p.mutedForeground),
            ],
          ),
        ),
      ],
    );
  }
}
