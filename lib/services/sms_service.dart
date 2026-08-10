import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

import 'categorization_service.dart';
import 'database_service.dart';
import 'app_state.dart';

/// Top-level function to handle background SMS processing.
/// This must be a top-level function per the telephony package requirements.
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // Ensure Flutter bindings are initialized in the background isolate
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Received background SMS: ${message.body}');

  if (message.body == null || message.body!.isEmpty) return;

  // Use AppState to ensure UI updates if we are in the foreground.
  // In the background isolate, this safely initializes a fresh instance.
  final appState = AppState();
  await appState.init();

  // Try to parse the SMS
  final parsed = CategorizationService().parseSms(message.body!, message.address ?? 'Unknown');
  
  if (parsed != null && parsed['type'] != 'Unknown') {
    final amount = parsed['amount'] as double;
    if (amount > 0) {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        amount: amount,
        type: parsed['type'] as String,
        paymentMode: parsed['paymentMode'] as String,
        merchant: parsed['merchant'] as String,
        category: 'Uncategorized', // Real categorize logic can go here
        subcategory: '',
        source: 'SMS',
        rawText: message.body!,
        accountNo: parsed['accountNo'] as String? ?? '',
        bankRefNo: parsed['bankRefNo'] as String? ?? '',
      );

      await appState.addTransaction(transaction);
      debugPrint('Transaction saved from background SMS!');
    }
  }
}

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony _telephony = Telephony.instance;

  Future<bool> requestSmsPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> checkSmsPermissions() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  void startListening() {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        debugPrint('Received foreground SMS: ${message.body}');
        // Process foreground message identically to background
        backgroundMessageHandler(message);
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
    debugPrint('SMS Listener started.');
  }
}
