import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ovce.dart';

class PdfExportService {
  
  Future<pw.Document> createOvceRegistrPdf(List<Ovce> ovce) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    // Omezit na prvních 10 podle dokumentu
    final displayedOvce = ovce.take(10).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Hlavička podle dokumentu
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Stájový registr - Registr, Aneta Šenohrová CZ 32043484, CZ 32043484 stáj 01",
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Datum: ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}, Počet identifikovaných zvířat: ${ovce.length}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Text(
                    "Tiskne se pouze prvních 10",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              
              // Tabulka podle struktury z dokumentu
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80), // Ušní číslo
                  1: const pw.FixedColumnWidth(60), // Dat. nar.
                  2: const pw.FixedColumnWidth(40), // Matka
                  3: const pw.FixedColumnWidth(40), // Otec
                  4: const pw.FixedColumnWidth(60), // Plemeno
                  5: const pw.FixedColumnWidth(50), // Kategorie
                  6: const pw.FixedColumnWidth(80), // Číslo matky individuální
                  7: const pw.FixedColumnWidth(60), // Pohlaví individuální
                  8: const pw.FixedColumnWidth(40), // Max OL
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Ušní číslo', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Dat. nar.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Matka', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Otec', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Plemeno', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Kategorie', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Číslo matky individuální', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Pohlaví individuální', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('Max OL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  // Data rows
                  ...displayedOvce.map((ovce) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(ovce.usiCislo, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('${ovce.datumNarozeni.day.toString().padLeft(2, '0')}.${ovce.datumNarozeni.month.toString().padLeft(2, '0')}.${ovce.datumNarozeni.year}', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('-', style: const pw.TextStyle(fontSize: 8)), // Matka - prázdné
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(ovce.pohlavi == 'beran' ? 'samec' : '-', style: const pw.TextStyle(fontSize: 8)), // Otec pouze pro samce
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(ovce.plemeno, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(ovce.kategorie, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('CZ000000${(1000 + displayedOvce.indexOf(ovce)).toString()}', style: const pw.TextStyle(fontSize: 7)), // Generované číslo
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(ovce.pohlavi, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('935', style: const pw.TextStyle(fontSize: 8)), // Standardní Max OL
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Poznámky na konci podle dokumentu
              pw.Text('Poznámky:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Text('1', style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(width: 20),
                  pw.Text('Celkem: ${ovce.length}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<File> savePdfToFile(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> showPrintPreview(pw.Document pdf, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: title,
    );
  }

  Future<void> sharePdf(pw.Document pdf, String fileName) async {
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName,
    );
  }

  Future<void> exportOvceToPDF(List<Ovce> ovce, {String action = 'save', String? customFileName}) async {
    final pdf = await createOvceRegistrPdf(ovce);
    final fileName = customFileName ?? 'ovce_registr_${DateTime.now().millisecondsSinceEpoch}.pdf';

    switch (action) {
      case 'print':
        await showPrintPreview(pdf, 'Registr ovcí');
        break;
      case 'share':
        await sharePdf(pdf, fileName);
        break;
      case 'save':
      default:
        await savePdfToFile(pdf, fileName);
        break;
    }
  }
}
