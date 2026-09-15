import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A summary card showing a financial figure (Balance, Income, or Expenses)
class SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isWide; // true = takes full width, false = half width

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWide ? color : AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWide ? Colors.transparent : AppConstants.cardBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isWide
                ? color.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isWide
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isWide ? Colors.white : color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isWide
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: isWide ? 26 : 20,
              fontWeight: FontWeight.bold,
              color: isWide ? Colors.white : AppConstants.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
