import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../utils/constants.dart';

/// Card displaying a budget with a progress bar
class BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final double spent;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget.amount > 0
        ? (spent / budget.amount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = budget.amount - spent;
    final isExceeded = spent > budget.amount;
    final isWarning = !isExceeded && progress >= 0.8;

    Color progressColor;
    String statusText;
    if (isExceeded) {
      progressColor = AppConstants.expenseColor;
      statusText = '⚠️ Budget exceeded';
    } else if (isWarning) {
      progressColor = AppConstants.warningColor;
      statusText = '⚡ Approaching budget limit';
    } else {
      progressColor = AppConstants.incomeColor;
      statusText = '✓ Within budget';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.categoryColor(budget.category)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.categoryColor(budget.category)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  AppConstants.categoryIcon(budget.category),
                  color: AppConstants.categoryColor(budget.category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  budget.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppConstants.textMuted, size: 18),
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppConstants.expenseColor)),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.currencySymbol}${_fmt(spent)} / ${AppConstants.currencySymbol}${_fmt(budget.amount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% used',
                style: TextStyle(
                  fontSize: 12,
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppConstants.neoPill,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: progressColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isExceeded
                    ? 'Over by ${AppConstants.currencySymbol}${_fmt(spent - budget.amount)}'
                    : 'Remaining: ${AppConstants.currencySymbol}${_fmt(remaining)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double amount) {
    return NumberFormat('#,##0', 'en_US').format(amount);
  }
}
