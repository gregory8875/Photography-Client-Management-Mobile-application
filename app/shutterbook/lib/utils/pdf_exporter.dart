// Shutterbook — PDF Exporter
// Utility to generate PDF documents for quotes.
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/utils/formatters.dart';

class PdfExporter {
  /// Generate a PDF for a quote
  static Future<File> generateQuotePdf(Quote quote, Client client) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'QUOTE',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Quote Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Quote #${quote.id}',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: ${formatDateTime(quote.createdAt)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Client Information',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('${client.firstName} ${client.lastName}'),
                      pw.Text(client.email),
                      pw.Text(client.phone),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Description
              pw.Text('Description',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(quote.description),
              pw.SizedBox(height: 30),

              // Total
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total: ',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatRand(quote.totalPrice),
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/quote_${quote.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
