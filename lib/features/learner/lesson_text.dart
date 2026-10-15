/// Lesson text, ready for the Markdown renderer.
///
/// Facilitators often write lessons as plain text, with section titles on their own line
/// ("🎯 Learning Objectives") and the lesson title repeated at the top. Markdown would run those
/// titles into the next sentence. This turns such lines into headings and drops a first line that
/// only repeats the title. Text that already uses Markdown headings is left as written.
String lessonMarkdown(String content, {String title = ''}) {
  final text = content.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty || RegExp(r'^#{1,6} ', multiLine: true).hasMatch(text)) return text;

  final lines = text.split('\n');
  final out = <String>[];
  final cleanTitle = _normalise(title);
  var first = true;
  for (final raw in lines) {
    final line = raw.trim();
    if (first && line.isNotEmpty) {
      first = false;
      // "Lesson 1.1: What Does a Cloud Engineer Do?" when the title is "What Does a Cloud Engineer Do?"
      if (cleanTitle.isNotEmpty && _normalise(line).endsWith(cleanTitle)) continue;
    }
    if (_isSectionTitle(line)) {
      out
        ..add('')
        ..add('### $line')
        ..add('');
    } else {
      out.add(raw);
    }
  }
  // Collapse the runs of blank lines plain-text editors leave behind.
  return out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String _normalise(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// A short line that starts with an emoji or symbol, and isn't already Markdown: a section title.
bool _isSectionTitle(String line) {
  if (line.isEmpty || line.length > 70) return false;
  if (RegExp(r'^([-*+>#|]|\d+[.)]\s)').hasMatch(line)) return false;
  final firstRune = line.runes.first;
  final startsWithSymbol = firstRune > 0x2000 && !RegExp(r'[A-Za-z0-9]').hasMatch(String.fromCharCode(firstRune));
  return startsWithSymbol && !line.endsWith('.') && !line.endsWith(',');
}
