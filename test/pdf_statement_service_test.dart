import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sense/services/database_service.dart';
import 'package:spend_sense/services/pdf_statement_service.dart';

void main() {
  test('generateStatementBytes returns non-empty PDF bytes', () async {
    final transactions = [
      Transaction(
        id: '1',
        date: DateTime.now(),
        amount: 450.0,
        type: 'debit',
        paymentMode: 'UPI',
        merchant: 'Swiggy',
        category: 'Food',
        subcategory: 'Restaurant',
        source: 'SMS',
        rawText: 'Paid Rs 450 to Swiggy',
        bankRefNo: 'UPI12345678',
      ),
      Transaction(
        id: '2',
        date: DateTime.now().subtract(const Duration(hours: 3)),
        amount: 25000.0,
        type: 'credit',
        paymentMode: 'Bank Transfer',
        merchant: 'Salary Corp',
        category: 'Income',
        subcategory: 'Salary',
        source: 'SMS',
        rawText: 'Credited Rs 25000 from Salary Corp',
        bankRefNo: 'SAL98765432',
      ),
    ];

    final bytes = await PdfStatementService.generateStatementBytes(
      transactions: transactions,
      accountHolder: 'Test User',
      periodTitle: 'Test Period Statement',
    );

    expect(bytes, isNotEmpty);
    // PDF magic number header "%PDF"
    expect(String.fromCharCodes(bytes.take(4)), equals('%PDF'));
  });
}
