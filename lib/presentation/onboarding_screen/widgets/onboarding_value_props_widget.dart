import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class OnboardingValuePropsWidget extends StatefulWidget {
  final VoidCallback onNext;
  const OnboardingValuePropsWidget({required this.onNext, super.key});

  @override
  State<OnboardingValuePropsWidget> createState() =>
      _OnboardingValuePropsWidgetState();
}

class _OnboardingValuePropsWidgetState
    extends State<OnboardingValuePropsWidget> {
  final PageController _innerController = PageController();
  int _innerPage = 0;

  final List<_ValueProp> _props = const [
    _ValueProp(
      icon: Icons.sms_outlined,
      color: AppTheme.primary,
      title: 'Reads Your Bank SMS',
      description:
          'SpendSense automatically detects transactions from HDFC, SBI, ICICI, Axis, Paytm, PhonePe, and all major banks — no manual entry needed.',
    ),
    _ValueProp(
      icon: Icons.lock_outline_rounded,
      color: Color(0xFF00B894),
      title: 'Your Data Never Leaves',
      description:
          'We never ask for your banking password. All transaction data is stored on your device only — never uploaded to any server.',
    ),
    _ValueProp(
      icon: Icons.lightbulb_outline_rounded,
      color: AppTheme.secondary,
      title: 'Plain-English Summaries',
      description:
          'Instead of raw numbers, SpendSense tells you "You spent ₹3,200 on food this week — 40% was Swiggy on weekends." Real insights, not just data.',
    ),
  ];

  @override
  void dispose() {
    _innerController.dispose();
    super.dispose();
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
            'How it works',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simple, private, and powerful',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _innerController,
              onPageChanged: (i) => setState(() => _innerPage = i),
              itemCount: _props.length,
              itemBuilder: (ctx, i) {
                return _ValuePropCard(prop: _props[i]);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_props.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _innerPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _innerPage == i
                      ? AppTheme.primary
                      : AppTheme.primary.withAlpha(64),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const Spacer(),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ValueProp {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _ValueProp({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _ValuePropCard extends StatelessWidget {
  final _ValueProp prop;
  const _ValuePropCard({required this.prop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: prop.color.withAlpha(31),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: prop.color.withAlpha(31),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(prop.icon, size: 36, color: prop.color),
          ),
          const SizedBox(height: 24),
          Text(
            prop.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            prop.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
