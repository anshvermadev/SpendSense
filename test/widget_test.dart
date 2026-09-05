import 'package:flutter_test/flutter_test.dart';
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
}
