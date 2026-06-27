import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hane/models/financial_transaction.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/utils/formatters.dart';

const List<String> _transactionHeaders = ['Tarih', 'Tür', 'Kategori', 'Açıklama', 'Cari/Hesap', 'Tutar'];

/// Hareketler, Cari Hesap Ekstresi ve Proje Maliyet Raporu için PDF/Excel
/// dışa aktarma. Tamamen istemci tarafında çalışır — veri zaten ekranda
/// filtrelenmiş halde elde olduğu için sunucuya yeni bir endpoint eklemeye
/// gerek yoktur.
class ExportService {
  ExportService._();

  static Future<pw.ThemeData> _pdfTheme() async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  static List<String> _row(FinancialTransaction t) {
    final counterparty =
        t.contactName.isNotEmpty ? t.contactName : (t.destName.isNotEmpty ? t.destName : t.sourceName);
    return [
      t.date,
      t.type,
      t.category.isNotEmpty ? t.category : '-',
      t.description.isNotEmpty ? t.description : '-',
      counterparty.isNotEmpty ? counterparty : '-',
      currencyFormat.format(t.amount),
    ];
  }

  static String _slug(String s) {
    final cleaned = s.trim().replaceAll(RegExp(r'[^\w]+'), '_');
    return cleaned.isEmpty ? 'disa_aktarim' : cleaned;
  }

  // ── Hareket listesi (Hareketler ekranı, Cari ekstresi) ──────────────────────

  static Future<void> exportTransactionsPdf(List<FinancialTransaction> transactions, {required String title}) async {
    final doc = pw.Document(theme: await _pdfTheme());
    final rows = transactions.map(_row).toList();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: title),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('Bu kritere uyan işlem bulunamadı.')
          else
            pw.TableHelper.fromTextArray(
              headers: _transactionHeaders,
              data: rows,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {5: pw.Alignment.centerRight},
            ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: '${_slug(title)}.pdf');
  }

  static Future<void> exportTransactionsExcel(List<FinancialTransaction> transactions, {required String title}) async {
    final book = Excel.createExcel();
    final sheetName = book.getDefaultSheet()!;
    final sheet = book[sheetName];
    sheet.appendRow(_transactionHeaders.map((h) => TextCellValue(h)).toList());
    for (final t in transactions) {
      final counterparty =
          t.contactName.isNotEmpty ? t.contactName : (t.destName.isNotEmpty ? t.destName : t.sourceName);
      sheet.appendRow([
        TextCellValue(t.date),
        TextCellValue(t.type),
        TextCellValue(t.category),
        TextCellValue(t.description),
        TextCellValue(counterparty),
        DoubleCellValue(t.amount),
      ]);
    }
    await _shareBytes(book.encode(), '${_slug(title)}.xlsx');
  }

  // ── Proje maliyet raporu (hareketler + bütçe kalemleri) ─────────────────────

  static Future<void> exportProjectCostReportPdf(
    String projectName,
    List<FinancialTransaction> transactions,
    List<BudgetLine> budgetLines,
  ) async {
    final doc = pw.Document(theme: await _pdfTheme());
    final rows = transactions.map(_row).toList();
    final budgetRows = budgetLines
        .map((b) => [
              b.category,
              currencyFormat.format(b.budgetedAmount),
              currencyFormat.format(b.actualAmount),
              currencyFormat.format(b.remaining),
            ])
        .toList();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Proje Maliyet Raporu — $projectName'),
          pw.SizedBox(height: 12),
          if (budgetRows.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Bütçe Özeti'),
            pw.TableHelper.fromTextArray(
              headers: const ['Kategori', 'Planlanan', 'Gerçekleşen', 'Kalan'],
              data: budgetRows,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Header(level: 1, text: 'Harcamalar'),
          if (rows.isEmpty)
            pw.Text('Bu projeye ait harcama bulunamadı.')
          else
            pw.TableHelper.fromTextArray(
              headers: _transactionHeaders,
              data: rows,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: '${_slug('proje_maliyet_raporu_$projectName')}.pdf');
  }

  static Future<void> exportProjectCostReportExcel(
    String projectName,
    List<FinancialTransaction> transactions,
    List<BudgetLine> budgetLines,
  ) async {
    final book = Excel.createExcel();
    final budgetSheet = book['Bütçe'];
    budgetSheet.appendRow([
      TextCellValue('Kategori'),
      TextCellValue('Planlanan'),
      TextCellValue('Gerçekleşen'),
      TextCellValue('Kalan'),
    ]);
    for (final b in budgetLines) {
      budgetSheet.appendRow([
        TextCellValue(b.category),
        DoubleCellValue(b.budgetedAmount),
        DoubleCellValue(b.actualAmount),
        DoubleCellValue(b.remaining),
      ]);
    }

    final txSheet = book['Harcamalar'];
    txSheet.appendRow(_transactionHeaders.map((h) => TextCellValue(h)).toList());
    for (final t in transactions) {
      txSheet.appendRow([
        TextCellValue(t.date),
        TextCellValue(t.type),
        TextCellValue(t.category),
        TextCellValue(t.description),
        TextCellValue(t.contactName),
        DoubleCellValue(t.amount),
      ]);
    }
    book.delete(book.getDefaultSheet()!);
    await _shareBytes(book.encode(), '${_slug('proje_maliyet_raporu_$projectName')}.xlsx');
  }

  static Future<void> _shareBytes(List<int>? bytes, String filename) async {
    if (bytes == null) throw Exception('Dosya oluşturulamadı');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}
