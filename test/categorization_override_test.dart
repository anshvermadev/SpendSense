import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sense/services/app_state.dart';
import 'package:spend_sense/services/categorization_service.dart';
import 'package:spend_sense/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService().refresh();
    await DatabaseService().deleteAllData();
  });

  group('Interactive Categorization, Sticky Overrides & Retroactive History', () {
    test('Identifies uncertain transactions correctly', () async {
      final appState = AppState();
      await appState.init();

      // Add normal known transaction
      await appState.addTransaction(
        Transaction(
          id: '1',
          date: DateTime.now(),
          amount: 500,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Swiggy',
          category: 'Food',
          subcategory: 'Delivery',
          source: 'SMS',
          rawText: '',
          accountNo: '',
          bankRefNo: '',
          status: 'success',
        ),
      );

      // Add uncertain / peer transfer transactions
      await appState.addTransaction(
        Transaction(
          id: '2',
          date: DateTime.now().subtract(const Duration(days: 2)),
          amount: 800,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Rahul Sharma',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: '',
          accountNo: '',
          bankRefNo: '',
          status: 'success',
        ),
      );

      await appState.addTransaction(
        Transaction(
          id: '3',
          date: DateTime.now().subtract(const Duration(days: 1)),
          amount: 250,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Rahul Sharma',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: '',
          accountNo: '',
          bankRefNo: '',
          status: 'success',
        ),
      );

      final uncertain = appState.getUncertainTransactions();
      // Should find Rahul Sharma once (deduplicated by merchant)
      expect(uncertain.length, equals(1));
      expect(uncertain.first.merchant, equals('Rahul Sharma'));
    });

    test('Assigning category retroactively updates all history and creates sticky override', () async {
      final appState = AppState();
      await appState.init();

      // Seed 2 past transactions for "Pooja Gupta"
      await appState.addTransaction(
        Transaction(
          id: 'txn-1',
          date: DateTime.now().subtract(const Duration(days: 5)),
          amount: 1200,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Pooja Gupta',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: 'Acct XX888 debited for Rs 1200.00; Pooja Gupta credited.',
          accountNo: 'XX888',
          bankRefNo: '111222',
          status: 'success',
        ),
      );

      await appState.addTransaction(
        Transaction(
          id: 'txn-2',
          date: DateTime.now().subtract(const Duration(days: 2)),
          amount: 450,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Pooja Gupta',
          category: 'Friends & Family',
          subcategory: '',
          source: 'SMS',
          rawText: 'Acct XX888 debited for Rs 450.00; Pooja Gupta credited.',
          accountNo: 'XX888',
          bankRefNo: '333444',
          status: 'success',
        ),
      );

      // User assigns "Food" to "Pooja Gupta"
      await appState.assignMerchantCategory(
        merchant: 'Pooja Gupta',
        category: 'Food',
        subcategory: 'Restaurant',
        updateAllForMerchant: true,
      );

      // Check retroactive updates in history
      final history = appState.allTransactions;
      final t1 = history.firstWhere((t) => t.id == 'txn-1');
      final t2 = history.firstWhere((t) => t.id == 'txn-2');
      expect(t1.category, equals('Food'));
      expect(t1.subcategory, equals('Restaurant'));
      expect(t2.category, equals('Food'));
      expect(t2.subcategory, equals('Restaurant'));

      // Check sticky override in DatabaseService
      expect(appState.db.getCategoryOverride('Pooja Gupta'), equals('Food'));
      expect(appState.db.getSubcategoryOverride('Pooja Gupta'), equals('Restaurant'));

      // Pooja Gupta should NO LONGER be uncertain
      expect(appState.getUncertainTransactions().where((t) => t.merchant == 'Pooja Gupta').isEmpty, isTrue);

      // Future SMS parsing for Pooja Gupta must automatically be Food!
      const newSms = 'Acct XX888 debited for Rs 900.00 on 10-Sep-26; Pooja Gupta credited. UPI:999888.';
      final parsed = CategorizationService().parseSms(newSms, 'ICICI');
      expect(parsed, isNotNull);
      expect(parsed!['merchant'], equals('Pooja Gupta'));
      expect(parsed['category'], equals('Food'));
      expect(parsed['subcategory'], equals('Restaurant'));
    });

    test('User mistake correction retroactively cascades across all past transactions and overrides', () async {
      final appState = AppState();
      await appState.init();

      // Transaction initially created
      await appState.addTransaction(
        Transaction(
          id: 'txn-10',
          date: DateTime.now().subtract(const Duration(days: 1)),
          amount: 5000,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Aman Landlord',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: '',
          accountNo: '',
          bankRefNo: '',
          status: 'success',
        ),
      );

      // Mistakenly assigned to Entertainment
      await appState.updateTransactionCategory('txn-10', 'Entertainment', 'Movies', updateAllForMerchant: true);
      expect(appState.db.getCategoryOverride('Aman Landlord'), equals('Entertainment'));

      // User corrects mistake in Transaction Detail to "Housing" (Rent)
      await appState.updateTransactionCategory('txn-10', 'Housing', 'Rent', updateAllForMerchant: true);

      final updatedTxn = appState.allTransactions.firstWhere((t) => t.id == 'txn-10');
      expect(updatedTxn.category, equals('Housing'));
      expect(updatedTxn.subcategory, equals('Rent'));

      // Override is updated
      expect(appState.db.getCategoryOverride('Aman Landlord'), equals('Housing'));
      expect(appState.db.getSubcategoryOverride('Aman Landlord'), equals('Rent'));

      // Future transactions use corrected category
      expect(CategorizationService().categorize('Aman Landlord'), equals('Housing'));
    });

    test('Deleting sole transaction clears merchant override and resets categorization for future payments', () async {
      final appState = AppState();
      await appState.init();

      // User has 1 transaction for "Jagdish Mangila"
      await appState.addTransaction(
        Transaction(
          id: 'txn-jm-1',
          date: DateTime.now(),
          amount: 35,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Jagdish Mangila',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: 'Acct debited Rs 35; Jagdish Mangila credited',
          accountNo: 'XX888',
          bankRefNo: 'REF-JM-1',
          status: 'success',
        ),
      );

      // User assigns "Food"
      await appState.assignMerchantCategory(
        merchant: 'Jagdish Mangila',
        category: 'Food',
        subcategory: 'Street Food',
        updateAllForMerchant: true,
      );

      expect(appState.db.getCategoryOverride('Jagdish Mangila'), equals('Food'));

      // Now user deletes that sole transaction
      await appState.deleteTransaction('txn-jm-1');

      // 1. Transaction must be removed from history
      expect(appState.allTransactions.where((t) => t.id == 'txn-jm-1').isEmpty, isTrue);

      // 2. Merchant override MUST be cleared because no transactions remain!
      expect(appState.db.getCategoryOverride('Jagdish Mangila'), isNull);

      // 3. Attempting to re-add the deleted transaction (e.g. from SMS re-read) must be blocked!
      await appState.addTransaction(
        Transaction(
          id: 'txn-jm-1',
          date: DateTime.now(),
          amount: 35,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Jagdish Mangila',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: 'Acct debited Rs 35; Jagdish Mangila credited',
          accountNo: 'XX888',
          bankRefNo: 'REF-JM-1',
          status: 'success',
        ),
      );
      expect(appState.allTransactions.where((t) => t.id == 'txn-jm-1').isEmpty, isTrue);

      // 4. A NEW future transaction from Jagdish Mangila should prompt for categorization again!
      await appState.addTransaction(
        Transaction(
          id: 'txn-jm-2',
          date: DateTime.now(),
          amount: 40,
          type: 'debit',
          paymentMode: 'UPI',
          merchant: 'Jagdish Mangila',
          category: 'Uncategorised',
          subcategory: '',
          source: 'SMS',
          rawText: 'Acct debited Rs 40; Jagdish Mangila credited',
          accountNo: 'XX888',
          bankRefNo: 'REF-JM-2',
          status: 'success',
        ),
      );

      final uncertain = appState.getUncertainTransactions();
      expect(uncertain.any((t) => t.merchant == 'Jagdish Mangila'), isTrue);
    });
  });
}
