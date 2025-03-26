import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:aqua_bill/models/customer.dart';
import 'package:aqua_bill/models/delivery.dart';
import 'package:aqua_bill/models/payment.dart';

class PdfService {
  static Future<void> generateAndPrintMonthlyReport({
    required List<Customer> customers,
    required List<Delivery> deliveries,
    required List<Payment> payments,
    required DateTime month,
  }) async {
    final pdf = pw.Document();
    final font = await rootBundle.load("assets/fonts/Nunito-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    final boldFont = await rootBundle.load("assets/fonts/Nunito-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFont);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs');

    // Calculate monthly statistics
    final monthlyDeliveries =
        deliveries.where((d) {
          return d.date.year == month.year && d.date.month == month.month;
        }).toList();

    final monthlyPayments =
        payments.where((p) {
          return p.date.year == month.year && p.date.month == month.month;
        }).toList();

    final totalBottles = monthlyDeliveries.fold<int>(
      0,
      (sum, d) => sum + d.bottles,
    );
    final totalRevenue = monthlyDeliveries.fold<double>(
      0,
      (sum, d) => sum + d.totalAmount,
    );
    final totalCollected = monthlyPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final collectionRate =
        totalRevenue > 0 ? (totalCollected / totalRevenue) * 100 : 0;
    final activeCustomers = customers.where((c) => c.isActive).length;

    pdf.addPage(
      pw.MultiPage(
        maxPages: 20,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final List<pw.Widget> widgets = [];

          // Header
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Monthly Business Report',
                    style: pw.TextStyle(font: boldTtf, fontSize: 24),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          // Overview Section
          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Business Overview',
                  style: pw.TextStyle(font: boldTtf, fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildOverviewItem(
                      'Active Customers',
                      activeCustomers.toString(),
                      ttf,
                      boldTtf,
                    ),
                    _buildOverviewItem(
                      'Total Bottles Delivered',
                      totalBottles.toString(),
                      ttf,
                      boldTtf,
                    ),
                    _buildOverviewItem(
                      'Total Revenue',
                      currencyFormat.format(totalRevenue),
                      ttf,
                      boldTtf,
                    ),
                    _buildOverviewItem(
                      'Total Collections',
                      currencyFormat.format(totalCollected),
                      ttf,
                      boldTtf,
                    ),
                    _buildOverviewItem(
                      'Collection Rate',
                      '${collectionRate.toStringAsFixed(1)}%',
                      ttf,
                      boldTtf,
                    ),
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          // Deliveries Section
          if (monthlyDeliveries.isNotEmpty) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Monthly Deliveries',
                    style: pw.TextStyle(font: boldTtf, fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    headerStyle: pw.TextStyle(font: boldTtf),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellStyle: pw.TextStyle(font: ttf),
                    cellHeight: 25,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1.5),
                    },
                    headers: ['Date', 'Bottles', 'Amount'],
                    data:
                        monthlyDeliveries
                            .map(
                              (d) => [
                                DateFormat('dd/MM/yyyy').format(d.date),
                                d.bottles.toString(),
                                currencyFormat.format(d.totalAmount),
                              ],
                            )
                            .toList(),
                  ),
                ],
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 20));

          // Payments Section
          if (monthlyPayments.isNotEmpty) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Monthly Payments',
                    style: pw.TextStyle(font: boldTtf, fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    headerStyle: pw.TextStyle(font: boldTtf),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellStyle: pw.TextStyle(font: ttf),
                    cellHeight: 25,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1.5),
                    },
                    headers: ['Date', 'Amount'],
                    data:
                        monthlyPayments
                            .map(
                              (p) => [
                                DateFormat('dd/MM/yyyy').format(p.date),
                                currencyFormat.format(p.amount),
                              ],
                            )
                            .toList(),
                  ),
                ],
              ),
            );
          }

          return widgets;
        },
        footer:
            (context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: ttf, color: PdfColors.grey700),
              ),
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildOverviewItem(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 16)),
        ],
      ),
    );
  }
}
