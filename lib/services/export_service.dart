import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/word.dart';

class ExportService {
  /// PDF olarak export
  Future<File> exportToPDF(List<Word> words, String fileName) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Bilişim Kavramları Sözlüğü',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            ...words.map((word) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    word.term,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    word.definition,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Kategori: ${word.category}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            )),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// JSON olarak export
  Future<File> exportToJSON(List<Word> words, String fileName) async {
    final jsonList = words.map((w) => w.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.json');
    await file.writeAsString(jsonString);
    
    return file;
  }

  /// CSV olarak export
  Future<File> exportToCSV(List<Word> words, String fileName) async {
    final csv = StringBuffer();
    csv.writeln('Terim,Kategori,Tanım');
    
    for (var word in words) {
      csv.writeln('"${word.term}","${word.category}","${word.definition.replaceAll('"', '""')}"');
    }
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.csv');
    await file.writeAsString(csv.toString());
    
    return file;
  }

  /// Paylaş
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bilişim Kavramları Sözlüğü',
    );
  }
}

