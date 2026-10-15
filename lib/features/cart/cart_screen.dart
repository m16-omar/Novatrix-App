import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/cart.dart';
import '../../core/config/app_config.dart';
import '../../core/data_providers.dart';
import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/course.dart';
import '../../data/models/learning.dart';
import '../public/public_screens.dart' show CourseImage;

enum _Stage { cart, awaitingPayment, paid }

/// The courses someone wants, then checkout: they pay on the payment provider's page in the browser
/// and the app confirms the order when they come back. If AppConfig.allowsWebCheckout is switched
/// off (see its App Store note), the cart sends an enrollment enquiry instead.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  _Stage _stage = _Stage.cart;
  bool _busy = false;
  String? _error;
  String? _notice;
  String? _reference;
  List<String> _paidFor = const [];
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the browser: confirm the payment without making them tap anything.
    _lifecycle = AppLifecycleListener(onResume: () {
      if (_stage == _Stage.awaitingPayment) _confirm(quiet: true);
    });
    _resumePending();
    // The "added to your cart" message has done its job once the cart is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// A checkout started before the app was closed: pick it up and confirm it.
  Future<void> _resumePending() async {
    final raw = (await SharedPreferences.getInstance()).getString(CartController.pendingKey);
    if (raw == null || !mounted) return;
    final pending = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _reference = pending['reference'] as String?;
      _paidFor = (pending['courses'] as List).cast<String>();
      _stage = _Stage.awaitingPayment;
    });
    await _confirm(quiet: true);
  }

  Future<void> _setPending(String? reference, List<String> slugs) async {
    final prefs = await SharedPreferences.getInstance();
    if (reference == null) {
      await prefs.remove(CartController.pendingKey);
    } else {
      await prefs.setString(CartController.pendingKey, jsonEncode({'reference': reference, 'courses': slugs}));
    }
  }

  Future<void> _checkout(List<Course> courses) async {
    final session = ref.read(sessionProvider).value;
    if (session == null) {
      context.go('/login?from=/cart');
      return;
    }
    final slugs = courses.map((c) => c.slug).toList();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final start = await ref.read(learningRepositoryProvider).startCheckout(slugs);
      _reference = start.reference;
      _paidFor = slugs;
      if (start.paid) {
        await _enrolled();
      } else if (start.paymentUrl != null) {
        await _setPending(start.reference, slugs);
        setState(() => _stage = _Stage.awaitingPayment);
        final opened = await launchUrl(Uri.parse(start.paymentUrl!), mode: LaunchMode.externalApplication);
        if (!opened) setState(() => _error = "The payment page couldn't be opened. Please try again.");
      }
    } on ApiException catch (e) {
      if (e.code == 'email_not_verified') {
        if (mounted) context.go('/verify-email?send=1&from=/cart');
        return;
      }
      setState(() => _error = e.firstError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks the backend whether the payment went through.
  Future<void> _confirm({bool quiet = false}) async {
    final reference = _reference;
    if (reference == null || _busy) return;
    setState(() {
      _busy = true;
      if (!quiet) _error = null;
    });
    try {
      final order = await ref.read(learningRepositoryProvider).verifyCheckout(reference);
      switch (order.status) {
        case 'paid':
          await _enrolled();
        case 'failed' || 'cancelled':
          await _setPending(null, const []);
          setState(() {
            _stage = _Stage.cart;
            _error = "The payment didn't go through, so you haven't been charged. You can try again.";
          });
        default:
          if (!quiet) {
            setState(() => _notice = "We haven't received confirmation of your payment yet. "
                'If you finished paying, give it a minute and check again.');
          }
      }
    } on ApiException catch (e) {
      if (!quiet) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enrolled() async {
    await _setPending(null, const []);
    await ref.read(cartProvider.notifier).removeAll(_paidFor);
    ref.invalidate(enrollmentsProvider);
    ref.invalidate(ordersProvider);
    await ref.read(sessionProvider.notifier).refreshRoles();
    if (mounted) setState(() => _stage = _Stage.paid);
  }

  Future<void> _cancelPayment() async {
    await _setPending(null, const []);
    setState(() {
      _stage = _Stage.cart;
      _reference = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your cart')),
        body: switch (_stage) {
          _Stage.paid => _paidView(context),
          _Stage.awaitingPayment => _awaitingView(context),
          _Stage.cart => AsyncBody(provider: coursesProvider, builder: _cartView),
        },
      );

  Widget _cartView(List<Course> catalog) {
    final p = context.palette;
    final slugs = ref.watch(cartProvider);
    final signedIn = ref.watch(sessionProvider).value != null;
    final enrolled = signedIn
        ? {for (final e in ref.watch(enrollmentsProvider).value ?? const <Enrollment>[]) e.course.slug}
        : const <String>{};
    final bySlug = {for (final c in catalog) c.slug: c};
    final items = [for (final s in slugs) (s, bySlug[s])];
    final buyable = [for (final (s, c) in items) if (c != null && !enrolled.contains(s)) c];

    if (items.isEmpty) {
      return Padding(
        padding: pagePadding,
        child: EmptyState(
          icon: LucideIcons.shoppingCart,
          title: 'Your cart is empty.',
          message: 'Add courses from the catalog, then check out here.',
          action: GradientButton(label: 'Browse courses', expand: false, onPressed: () => context.go('/courses')),
        ),
      );
    }

    // Free courses cost nothing in any currency: show the total in the paid courses' currency.
    final paid = buyable.where((c) => !c.isFree).toList();
    final currency = (paid.isEmpty ? buyable : paid).firstOrNull?.currency ?? 'USD';
    final total = buyable.fold<double>(0, (sum, c) => sum + c.effectivePrice);
    return ListView(
      padding: pagePadding,
      children: [
        for (final (slug, course) in items) ...[
          _CartRow(
            slug: slug,
            course: course,
            enrolled: enrolled.contains(slug),
            onRemove: () => ref.read(cartProvider.notifier).remove(slug),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plural(buyable.length, 'course'), style: context.text.bodyMedium?.copyWith(color: p.mutedForeground)),
                  ),
                  Text('Total  ', style: context.text.bodyMedium?.copyWith(color: p.mutedForeground)),
                  Text(total == 0 ? 'Free' : formatMoney(total, currency), style: context.text.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[ErrorNote(_error!, title: "We couldn't start your checkout."), const SizedBox(height: 12)],
              // Only free courses: no payment at all, so they enroll directly on every platform.
              if (AppConfig.allowsWebCheckout || (buyable.isNotEmpty && paid.isEmpty)) ...[
                GradientButton(
                  key: const ValueKey('checkout'),
                  label: !signedIn
                      ? 'Log in to check out'
                      : paid.isEmpty
                          ? 'Enroll for free'
                          : 'Enroll now',
                  icon: LucideIcons.lock,
                  busy: _busy,
                  onPressed: buyable.isEmpty ? null : () => _checkout(buyable),
                ),
                const SizedBox(height: 8),
                Text(
                  'You pay securely on our payment provider\'s page, then come back here. Your courses appear in My learning.',
                  style: context.text.bodySmall,
                ),
              ] else ...[
                GradientButton(
                  key: const ValueKey('checkout'),
                  label: 'Ask about enrolling',
                  icon: LucideIcons.messageSquare,
                  onPressed: buyable.isEmpty
                      ? null
                      : () => context.push(
                            '/training-inquiry?individual=1&topic=${Uri.encodeQueryComponent(buyable.map((c) => c.title).join(', '))}',
                          ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tell us you're interested and we'll get in touch about enrollment and the next cohort. "
                  'Courses you are enrolled in appear in My learning.',
                  style: context.text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _awaitingView(BuildContext context) => ListView(
        padding: pagePadding,
        children: [
          const SizedBox(height: 24),
          Icon(LucideIcons.creditCard, size: 44, color: context.palette.brand),
          const SizedBox(height: 16),
          Text('Finish paying in your browser', textAlign: TextAlign.center, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          Text(
            "When you've paid, come back here and we'll confirm your enrollment.",
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.palette.mutedForeground),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[ErrorNote(_error!), const SizedBox(height: 12)],
          if (_notice != null) ...[
            Text(_notice!, textAlign: TextAlign.center, style: context.text.bodyMedium),
            const SizedBox(height: 12),
          ],
          GradientButton(
            key: const ValueKey('confirm-payment'),
            label: "I've paid",
            icon: LucideIcons.circleCheck,
            busy: _busy,
            onPressed: () => _confirm(),
          ),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: _busy ? null : _cancelPayment, child: const Text('Back to my cart'))),
        ],
      );

  Widget _paidView(BuildContext context) => Padding(
        padding: pagePadding,
        child: EmptyState(
          icon: LucideIcons.partyPopper,
          title: "You're enrolled.",
          message: "Your courses are in My learning. We've emailed you a receipt.",
          action: GradientButton(label: 'Go to my courses', expand: false, onPressed: () => context.go('/learn')),
        ),
      );
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.slug, required this.course, required this.enrolled, required this.onRemove});

  final String slug;
  final Course? course;
  final bool enrolled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = course;
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: c == null ? null : () => context.push('/courses/${c.slug}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: 56,
              child: c == null
                  ? ColoredBox(color: p.muted, child: Icon(LucideIcons.circleSlash, color: p.mutedForeground))
                  : CourseImage(course: c, height: 56, compact: true),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c?.title ?? 'No longer available', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  c == null
                      ? 'This course is no longer offered.'
                      : enrolled
                          ? "You're already enrolled."
                          : c.priceLabel,
                  style: context.text.bodySmall?.copyWith(
                    color: enrolled || c == null ? p.warning : p.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${c?.title ?? 'course'}',
            onPressed: onRemove,
            icon: Icon(LucideIcons.trash2, size: 18, color: p.mutedForeground),
          ),
        ],
      ),
    );
  }
}
