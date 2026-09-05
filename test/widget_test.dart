import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sense/core/category_constants.dart';
import 'package:spend_sense/services/categorization_service.dart';
import 'package:spend_sense/services/ml_categorization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SpendSense core services instantiate cleanly', () {
    final categorizer = CategorizationService();
    expect(categorizer, isNotNull);

    final mlService = MlCategorizationService();
    expect(mlService, isNotNull);
    expect(mlService.isReady, isFalse);
  });

  test('CategoryConstants contains full 15-category set with colors and icons', () {
    expect(CategoryConstants.allCategories.length, greaterThanOrEqualTo(16));
    expect(CategoryConstants.allCategories, contains('Food'));
    expect(CategoryConstants.allCategories, contains('Groceries'));
    expect(CategoryConstants.allCategories, contains('Transport'));
    expect(CategoryConstants.allCategories, contains('Shopping'));
    expect(CategoryConstants.allCategories, contains('EMI'));
    expect(CategoryConstants.allCategories, contains('Utilities'));
    expect(CategoryConstants.allCategories, contains('Uncategorised'));

    for (final cat in CategoryConstants.allCategories) {
      expect(CategoryConstants.getColor(cat), isNotNull);
      expect(CategoryConstants.getIcon(cat), isNotNull);
    }
  });
}
