import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/word.dart';

enum ExportFormat {
  pdf('PDF document', 'pdf', 'application/pdf'),
  csv('CSV spreadsheet', 'csv', 'text/csv'),
  markdown('Markdown', 'md', 'text/markdown');

  const ExportFormat(this.label, this.extension, this.mimeType);

  final String label;
  final String extension;
  final String mimeType;
}

/// Renders a list of words as a PDF, CSV or Markdown file.
class ExportService {
  const ExportService();

  String fileName(ExportFormat format, {String base = 'tech-dictionary'}) =>
      '$base.${format.extension}';

  Future<Uint8List> build(ExportFormat format, List<Word> words) async {
    final sorted = [...words]
      ..sort((a, b) {
        final c = a.category.compareTo(b.category);
        return c != 0
            ? c
            : a.term.toLowerCase().compareTo(b.term.toLowerCase());
      });
    switch (format) {
      case ExportFormat.csv:
        return Uint8List.fromList(utf8.encode(toCsv(sorted)));
      case ExportFormat.markdown:
        return Uint8List.fromList(utf8.encode(toMarkdown(sorted)));
      case ExportFormat.pdf:
        return _toPdf(sorted);
    }
  }

  String toCsv(List<Word> words) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buffer = StringBuffer('Term,Category,Definition\r\n');
    for (final w in words) {
      buffer.write(
        '${esc(w.term)},${esc(w.category)},${esc(w.definition)}\r\n',
      );
    }
    return buffer.toString();
  }

  String toMarkdown(List<Word> words) {
    final buffer = StringBuffer('# Tech Dictionary\n');
    String? category;
    for (final w in words) {
      if (w.category != category) {
        category = w.category;
        buffer.write('\n## $category\n\n');
      }
      buffer.write('- **${w.term}**: ${w.definition}\n');
    }
    return buffer.toString();
  }

  Future<Uint8List> _toPdf(List<Word> words) async {
    final doc = pw.Document(title: 'Tech Dictionary');
    final grouped = <String, List<Word>>{};
    for (final w in words) {
      grouped.putIfAbsent(w.category, () => []).add(w);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(level: 0, text: 'Tech Dictionary'),
          pw.Text('${words.length} terms'),
          pw.SizedBox(height: 12),
          for (final entry in grouped.entries) ...[
            pw.Header(level: 1, text: entry.key),
            for (final w in entry.value)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${w.term}: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: w.definition),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
