import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class MlPrediction {
  final String category;
  final double categoryConfidence;
  final String merchant;
  final double merchantConfidence;

  const MlPrediction({
    required this.category,
    required this.categoryConfidence,
    required this.merchant,
    required this.merchantConfidence,
  });

  @override
  String toString() =>
      'MlPrediction(cat: $category [${(categoryConfidence * 100).toStringAsFixed(1)}%], '
      'merch: $merchant [${(merchantConfidence * 100).toStringAsFixed(1)}%])';
}

/// On-Device ML Categorization Service powered by SpendSense Character-Level CNN
class MlCategorizationService {
  static final MlCategorizationService _instance = MlCategorizationService._internal();
  factory MlCategorizationService() => _instance;
  MlCategorizationService._internal();

  Interpreter? _interpreter;
  Map<String, int> _vocab = {};
  List<String> _categoryLabels = [];
  List<String> _merchantLabels = [];

  int _catOutputIndex = -1;
  int _merchOutputIndex = -1;

  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isReady => _isInitialized && _interpreter != null;

  /// Initialize and load the TFLite model and metadata into memory
  Future<bool> init() async {
    if (_isInitialized) return true;
    if (_isInitializing) return false;
    _isInitializing = true;

    try {
      debugPrint('[MlCategorizationService] Loading model assets...');

      // 1. Load vocabulary
      final vocabStr = await rootBundle.loadString('assets/ml/vocabulary.json');
      final Map<String, dynamic> rawVocab = json.decode(vocabStr);
      _vocab = rawVocab.map((key, value) => MapEntry(key, value as int));

      // 2. Load category labels (15 classes)
      final catStr = await rootBundle.loadString('assets/ml/category_labels.json');
      _categoryLabels = List<String>.from(json.decode(catStr));

      // 3. Load merchant labels (734 classes)
      final merchStr = await rootBundle.loadString('assets/ml/merchant_labels.json');
      _merchantLabels = List<String>.from(json.decode(merchStr));

      // 4. Load TFLite interpreter
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/spendsense_dynamic_quant.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      // 5. Inspect outputs to dynamically bind tensor indices
      final outputTensors = _interpreter!.getOutputTensors();
      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        if (shape.contains(15)) {
          _catOutputIndex = i;
        } else if (shape.contains(734)) {
          _merchOutputIndex = i;
        }
      }

      debugPrint(
        '[MlCategorizationService] Model loaded successfully! '
        'Cat index: $_catOutputIndex, Merch index: $_merchOutputIndex',
      );

      _isInitialized = true;
      _isInitializing = false;
      return true;
    } catch (e, stack) {
      debugPrint('[MlCategorizationService] Error initializing ML model: $e\n$stack');
      _isInitializing = false;
      return false;
    }
  }

  /// Character-level tokenizer matching Python training preprocessing
  List<int> tokenize(String text, {int maxLen = 128}) {
    final cleaned = text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final tokens = <int>[];
    final padId = _vocab['<PAD>'] ?? 0;
    final unkId = _vocab['<UNK>'] ?? 1;

    for (int i = 0; i < cleaned.length && tokens.length < maxLen; i++) {
      final char = cleaned[i];
      tokens.add(_vocab[char] ?? unkId);
    }

    while (tokens.length < maxLen) {
      tokens.add(padId);
    }

    return tokens;
  }

  /// Run synchronous inference on extracted merchant / text string
  MlPrediction? predict(String merchantName) {
    if (!isReady || merchantName.trim().isEmpty) return null;

    try {
      final tokens = tokenize(merchantName);
      final input = [tokens]; // Shape: [1, 128]

      // Prepare output buffers
      final catOutput = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(_categoryLabels.length, 0.0),
      );
      final merchOutput = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(_merchantLabels.length, 0.0),
      );

      final outputs = {
        _catOutputIndex: catOutput,
        _merchOutputIndex: merchOutput,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      // Extract highest probability category
      int bestCatIdx = 0;
      double bestCatScore = catOutput[0][0];
      for (int i = 1; i < catOutput[0].length; i++) {
        if (catOutput[0][i] > bestCatScore) {
          bestCatScore = catOutput[0][i];
          bestCatIdx = i;
        }
      }

      // Extract highest probability merchant
      int bestMerchIdx = 0;
      double bestMerchScore = merchOutput[0][0];
      for (int i = 1; i < merchOutput[0].length; i++) {
        if (merchOutput[0][i] > bestMerchScore) {
          bestMerchScore = merchOutput[0][i];
          bestMerchIdx = i;
        }
      }

      return MlPrediction(
        category: _categoryLabels[bestCatIdx],
        categoryConfidence: bestCatScore,
        merchant: _merchantLabels[bestMerchIdx],
        merchantConfidence: bestMerchScore,
      );
    } catch (e) {
      debugPrint('[MlCategorizationService] Prediction error for "$merchantName": $e');
      return null;
    }
  }

  /// Dispose interpreter if needed
  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
