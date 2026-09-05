import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sense/services/categorization_service.dart';
import 'package:spend_sense/services/ml_categorization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategorizationService - Normalization & Parsing', () {
    final categorizer = CategorizationService();

    test('normalizeMerchant normalizes known aliases and strips noise', () {
      expect(categorizer.normalizeMerchant('DMART AVENUE SU'), equals('DMart'));
      expect(categorizer.normalizeMerchant('dmart'), equals('DMart'));
      expect(categorizer.normalizeMerchant('AVENUE SUPERMARTS'), equals('DMart'));
      expect(categorizer.normalizeMerchant('BIKANER SWEETS'), equals('Bikaner Sweets'));
      expect(categorizer.normalizeMerchant('bikanervala'), equals('Bikaner Sweets'));
      expect(categorizer.normalizeMerchant('AMZN Mktp'), equals('Amazon'));
      expect(categorizer.normalizeMerchant('Swiggy Instamart'), equals('Swiggy'));
      expect(categorizer.normalizeMerchant('Aviral Bhardwaj'), equals('Aviral Bhardwaj'));
    });

    test('parseSms correctly extracts amount, type, merchant and category for SMS 1', () {
      const sms1 =
          'Dear Customer, Acct XX888 is credited with Rs 3000.00 on 24-Aug-26 from Aviral Bhardwaj. UPI:313137621997-ICICI Bank.';
      final result = categorizer.parseSms(sms1, 'ICICI');
      expect(result, isNotNull);
      expect(result!['amount'], equals(3000.0));
      expect(result['type'], equals('credit'));
      expect(result['merchant'], equals('Aviral Bhardwaj'));
      expect(result['paymentMode'], equals('UPI'));
      expect(result['accountNo'], equals('XX888'));
      expect(result['bankRefNo'], equals('313137621997'));
    });

    test('parseSms correctly extracts and categorizes SMS 2 (DMart -> Groceries)', () {
      const sms2 =
          'ICICI Bank Acct XX888 debited for Rs 355.50 on 04-Sep-26; DMART AVENUE SU credited. UPI:661344826109. Call 18002662 for dispute. SMS BLOCK 888 to 9215676766.';
      final result = categorizer.parseSms(sms2, 'ICICI');
      expect(result, isNotNull);
      expect(result!['amount'], equals(355.50));
      expect(result['type'], equals('debit'));
      expect(result['merchant'], equals('DMart'));
      expect(result['category'], equals('Groceries'));
      expect(result['paymentMode'], equals('UPI'));
      expect(result['accountNo'], equals('XX888'));
      expect(result['bankRefNo'], equals('661344826109'));
    });

    test('parseSms correctly extracts and categorizes SMS 3 (Bikaner Sweets -> Food)', () {
      const sms3 =
          'ICICI Bank Acct XX888 debited for Rs 30.00 on 19-Jul-26; BIKANER SWEETS credited. UPI:620083461039. Call 18002662 for dispute. SMS BLOCK 888 to 9215676766.';
      final result = categorizer.parseSms(sms3, 'ICICI');
      expect(result, isNotNull);
      expect(result!['amount'], equals(30.0));
      expect(result['type'], equals('debit'));
      expect(result['merchant'], equals('Bikaner Sweets'));
      expect(result['category'], equals('Food'));
      expect(result['paymentMode'], equals('UPI'));
      expect(result['accountNo'], equals('XX888'));
      expect(result['bankRefNo'], equals('620083461039'));
    });
  });

  group('MlCategorizationService - Tokenizer & Contract', () {
    final mlService = MlCategorizationService();

    test('tokenize produces 128-token array padded with 0', () {
      final tokens = mlService.tokenize('dmart');
      expect(tokens.length, equals(128));
      // First tokens are non-zero, trailing are padded with 0
      expect(tokens[tokens.length - 1], equals(0));
    });

    test('predict returns null safely if service is not initialized', () {
      // Without calling init(), predict should return null safely without throwing
      expect(mlService.predict(''), isNull);
    });
  });
}
