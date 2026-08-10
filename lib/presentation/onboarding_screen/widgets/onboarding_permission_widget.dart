import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../services/sms_service.dart';

class OnboardingPermissionWidget extends StatefulWidget {
  final VoidCallback onNext;
  const OnboardingPermissionWidget({required this.onNext, super.key});

  @override
  State<OnboardingPermissionWidget> createState() =>
      _OnboardingPermissionWidgetState();
}

class _OnboardingPermissionWidgetState
    extends State<OnboardingPermissionWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  bool _permissionGranted = false;
  bool _isRequesting = false;

  Future<void> _requestSmsPermission() async {
    setState(() => _isRequesting = true);
    
    final smsService = SmsService();
    final isGranted = await smsService.requestSmsPermissions();
    
    if (isGranted) {
      smsService.startListening();
    }
    
    setState(() {
      _permissionGranted = isGranted;
      _isRequesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            'SMS Access',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For automatic transaction detection',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Privacy explanation card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withAlpha(51),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(20),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Your Privacy is Protected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _privacyPoint(
                  Icons.smartphone_outlined,
                  'On-device only',
                  'SpendSense reads your bank SMS on your device only, to automatically log transactions.',
                ),
                const SizedBox(height: 16),
                _privacyPoint(
                  Icons.cloud_off_outlined,
                  'Never uploaded',
                  'Nothing is ever sent to a server. Your transaction data stays on your phone.',
                ),
                const SizedBox(height: 16),
                _privacyPoint(
                  Icons.no_encryption_outlined,
                  'No passwords',
                  'We never ask for your banking login credentials. Ever.',
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_permissionGranted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SMS Access Granted',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestSmsPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Allow SMS Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onNext,
            child: Text(
              'Set up manually instead',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.textSecondary,
              ),
            ),
          ),
          if (_permissionGranted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _privacyPoint(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'DM Sans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                  fontFamily: 'DM Sans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
