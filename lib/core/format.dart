import 'package:intl/intl.dart';

String formatDate(DateTime? d) => d == null ? '—' : DateFormat('d MMM yyyy').format(d);

String formatMoney(double amount, String currency) {
  final format = NumberFormat.simpleCurrency(name: currency.isEmpty ? 'USD' : currency);
  return amount == amount.roundToDouble()
      ? NumberFormat.currency(name: currency, symbol: format.currencySymbol, decimalDigits: 0).format(amount)
      : format.format(amount);
}

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// "3 days ago" style, for activity and updates.
String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${plural(diff.inMinutes, 'minute')} ago';
  if (diff.inDays < 1) return '${plural(diff.inHours, 'hour')} ago';
  if (diff.inDays < 30) return '${plural(diff.inDays, 'day')} ago';
  return formatDate(d);
}
