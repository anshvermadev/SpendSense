import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'database_service.dart';

class PdfStatementService {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');
  static final DateFormat _headerDateFormat = DateFormat('dd MMMM yyyy');

  /// Generates and triggers the print / save PDF preview for the given transactions.
  static Future<void> generateAndDownloadStatement({
    required BuildContext context,
    required List<Transaction> transactions,
    required String accountHolder,
    String? periodTitle,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdfBytes = await generateStatementBytes(
      transactions: transactions,
      accountHolder: accountHolder,
      periodTitle: periodTitle,
      startDate: startDate,
      endDate: endDate,
    );

    final filename =
        'SpendSense_Statement_${_fileDateFormat.format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: filename,
    );
  }

  /// Generates the raw PDF bytes for an account statement.
  static Future<Uint8List> generateStatementBytes({
    required List<Transaction> transactions,
    required String accountHolder,
    String? periodTitle,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final doc = pw.Document();

    // Calculate statement statistics
    double totalDebits = 0;
    double totalCredits = 0;
    int debitCount = 0;
    int creditCount = 0;

    for (final t in transactions) {
      if (t.isCredit) {
        totalCredits += t.amount;
        creditCount++;
      } else {
        totalDebits += t.amount;
        debitCount++;
      }
    }

    final double netFlow = totalCredits - totalDebits;

    // Period label
    String periodText = periodTitle ?? 'Full Transaction History';
    if (startDate != null && endDate != null) {
      periodText =
          '${_headerDateFormat.format(startDate)} to ${_headerDateFormat.format(endDate)}';
    }

    final generatedOn = _dateFormat.format(DateTime.now());

    // Styling colors
    final primaryColor = PdfColor.fromHex('6C5CE7');
    final darkCardColor = PdfColor.fromHex('1E1E2C');
    final debitColor = PdfColor.fromHex('D63031');
    final creditColor = PdfColor.fromHex('00B894');
    final greyBg = PdfColor.fromHex('F5F5F7');
    final borderColor = PdfColor.fromHex('E0E0E8');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 24,
                      height: 24,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'S',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'SpendSense',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: darkCardColor,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'ACCOUNT STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'This is a computer-generated statement generated via SpendSense.',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 16),

            // Account & Statement Info Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: greyBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ACCOUNT HOLDER',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          accountHolder.isNotEmpty
                              ? accountHolder
                              : 'Primary Account User',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: darkCardColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Account Type: Personal Savings / Daily Expenses',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 48,
                    color: PdfColors.grey300,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                  ),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STATEMENT PERIOD',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          periodText,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: darkCardColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Generated On: $generatedOn',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Financial Summary Block
            pw.Row(
              children: [
                _buildSummaryBox(
                  title: 'TOTAL DEBITS',
                  value: 'INR ${_fmt(totalDebits)}',
                  subtitle: '$debitCount transactions',
                  valueColor: debitColor,
                ),
                pw.SizedBox(width: 10),
                _buildSummaryBox(
                  title: 'TOTAL CREDITS',
                  value: 'INR ${_fmt(totalCredits)}',
                  subtitle: '$creditCount transactions',
                  valueColor: creditColor,
                ),
                pw.SizedBox(width: 10),
                _buildSummaryBox(
                  title: 'NET MOVEMENT',
                  value:
                      '${netFlow >= 0 ? '+' : '-'}INR ${_fmt(netFlow.abs())}',
                  subtitle: '${transactions.length} total entries',
                  valueColor: netFlow >= 0 ? creditColor : darkCardColor,
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Section Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TRANSACTION DETAILS (${transactions.length})',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: darkCardColor,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  'Currency: INR',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            // Transactions Table
            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'No transactions recorded for this period.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    color: PdfColors.grey200,
                    width: 0.6,
                  ),
                  bottom: pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 0.8,
                  ),
                ),
                headerDecoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.vertical(
                    top: pw.Radius.circular(4),
                  ),
                ),
                headerHeight: 26,
                cellHeight: 24,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.black,
                ),
                headerAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                headers: [
                  'Date & Time',
                  'Description / Payee',
                  'Category',
                  'Mode / Ref',
                  'Debit (INR)',
                  'Credit (INR)',
                ],
                data: transactions.map((t) {
                  final ref = t.bankRefNo.isNotEmpty
                      ? 'Ref: ${t.bankRefNo}'
                      : (t.accountNo.isNotEmpty ? 'A/c: ${t.accountNo}' : t.source);
                  return [
                    _dateFormat.format(t.date),
                    t.merchant.isNotEmpty ? t.merchant : 'Unknown',
                    t.category,
                    '${t.paymentMode}\n$ref',
                    t.isCredit ? '-' : _fmt(t.amount),
                    t.isCredit ? _fmt(t.amount) : '-',
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSummaryBox({
    required String title,
    required String value,
    required String subtitle,
    required PdfColor valueColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey600,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }
}
