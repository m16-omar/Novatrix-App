/// Small helpers for reading API JSON without crashing on missing or null fields.
typedef Json = Map<String, dynamic>;

String str(Object? v) => v == null ? '' : '$v';
String? strOrNull(Object? v) => v == null || '$v'.isEmpty ? null : '$v';
int intOf(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
int? intOrNull(Object? v) => v == null ? null : (v is int ? v : int.tryParse('$v'));
double doubleOf(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
bool boolOf(Object? v) => v == true;
DateTime? dateOf(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
List<String> strings(Object? v) => (v as List? ?? const []).map((e) => '$e').toList();
List<Json> jsonList(Object? v) => (v as List? ?? const []).cast<Json>();
Json jsonOf(Object? v) => (v as Map?)?.cast<String, dynamic>() ?? const {};
