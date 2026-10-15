import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, ProviderOrFamily;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/user.dart';
import '../network/api_exception.dart';
import '../theme/app_theme.dart';

const pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 32);

/// The brand's primary button: a purple-to-pink pill, like the website's.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || busy ? 1 : 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: p.gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: p.brand.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? onPressed : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 52, minWidth: expand ? double.infinity : 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (busy)
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      else if (icon != null)
                        Icon(icon, size: 18, color: Colors.white),
                      if (busy || icon != null) const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: Size(expand ? double.infinity : 0, 52)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 10)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return child;
  }
}

/// The small uppercase gradient label above page titles ("MY LEARNING").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ShaderMask(
      shaderCallback: (rect) => p.gradient.createShader(rect),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.eyebrow, required this.title, this.intro});

  final String eyebrow;
  final String title;
  final String? intro;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 8),
          Text(title, style: context.text.headlineMedium),
          if (intro != null) ...[
            const SizedBox(height: 6),
            Text(intro!, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedForeground)),
          ],
        ],
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: context.text.titleLarge)),
            if (action != null)
              TextButton(
                onPressed: onAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(action!), const SizedBox(width: 4), const Icon(LucideIcons.arrowRight, size: 16)],
                ),
              ),
          ],
        ),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18), this.highlight});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(color: p.card, borderRadius: radius, boxShadow: p.cardShadow),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: highlight ?? p.border, width: highlight != null ? 1.5 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.label, required this.value, this.detail, this.highlight = false, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      highlight: highlight ? p.warning.withValues(alpha: 0.6) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.brand.withValues(alpha: 0.22), p.brand2.withValues(alpha: 0.14)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: p.brand),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.headlineMedium, maxLines: 1),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelLarge?.copyWith(color: p.mutedForeground)),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(detail!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// Two stat tiles per row.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth > 640 ? 4 : 2;
          final width = (c.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final child in children) SizedBox(width: width, child: child)],
          );
        },
      );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = value.clamp(0, 100);
    return Semantics(
      label: label,
      value: '$pct%',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: context.text.bodySmall)),
                Text('$pct%', style: context.text.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: p.muted),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct / 100,
                      child: DecoratedBox(decoration: BoxDecoration(gradient: p.gradient)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PillTone { neutral, brand, success, warning, danger }

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color? fill, Color border, Color fg) = switch (tone) {
      PillTone.brand => (null, Colors.transparent, Colors.white),
      PillTone.success => (null, p.success.withValues(alpha: 0.5), p.success),
      PillTone.warning => (null, p.warning.withValues(alpha: 0.5), p.warning),
      PillTone.danger => (null, p.destructive.withValues(alpha: 0.5), p.destructive),
      PillTone.neutral => (p.card, p.border, p.foreground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        gradient: tone == PillTone.brand ? p.gradient : null,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: tone == PillTone.neutral ? p.border : border),
      ),
      child: Text(label, style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.size = 40});

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: context.palette.gradient, shape: BoxShape.circle),
          child: Text(
            user?.initials ?? '?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36),
          ),
        ),
      );
}

class NovatrixLogo extends StatelessWidget {
  const NovatrixLogo({super.key, this.height = 40});
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        Theme.of(context).brightness == Brightness.dark
            ? 'assets/images/logo-on-dark.png'
            : 'assets/images/logo-on-light.png',
        height: height,
        semanticLabel: 'The Novatrix',
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 36, color: context.palette.brand),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: context.text.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: context.text.bodySmall),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      );
}

class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.destructive.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.destructive.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleAlert, size: 18, color: p.destructive),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: context.text.labelLarge?.copyWith(color: p.destructive)),
                  Text(message, style: context.text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading…'});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Semantics(
          label: label,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            ErrorNote(errorMessage(error), title: "We couldn't load this."),
            const SizedBox(height: 12),
            SecondaryButton(label: 'Try again', icon: LucideIcons.refreshCw, onPressed: onRetry, expand: false),
          ],
        ),
      );
}

/// Loading, error with retry, and data states for a provider, in one place.
class AsyncBody<T> extends ConsumerWidget {
  const AsyncBody({super.key, required this.provider, required this.builder, this.loadingLabel = 'Loading…'});

  final ProviderListenable<AsyncValue<T>> provider;
  final Widget Function(T data) builder;
  final String loadingLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return value.when(
      data: builder,
      loading: () => LoadingView(label: loadingLabel),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () {
          if (provider is ProviderOrFamily) ref.invalidate(provider as ProviderOrFamily);
        },
      ),
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
    );
  }
}

/// Opens a link outside the app (documents, videos, the website).
Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final ok = uri != null && (uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'mailto') &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("That link couldn't be opened.")));
  }
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
