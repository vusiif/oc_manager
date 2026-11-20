import 'dart:convert';
import 'package:archive/archive.dart';

void addArchiveString(Archive archive, String path, String content) {
  final bytes = utf8.encode(content);
  archive.addFile(ArchiveFile(path, bytes.length, bytes));
}

String sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
}

String formatDescription(String raw) {
  return raw
      .split('\n\n')
      .map((p) => '<p>${escapeHtml(p).replaceAll('\n', '<br/>')}</p>')
      .join('');
}

String formatWikiLinks(String raw) {
  final regex = RegExp(r'\[\[(.*?)\]\]');
  final paragraphs = raw.split('\n\n').map((p) {
    final escaped = escapeHtml(p).replaceAll('\n', '<br/>');
    return escaped.replaceAllMapped(regex, (m) {
      final target = m.group(1) ?? '';
      return '<span class="wiki-link">[[$target]]</span>';
    });
  });
  return paragraphs.map((p) => '<p>$p</p>').join('');
}
