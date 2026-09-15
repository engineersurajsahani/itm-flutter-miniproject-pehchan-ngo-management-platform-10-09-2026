import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

/// A single transaction row in a list
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool isLast;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == AppConstants.income;
    final color = isIncome ? AppConstants.incomeColor : Colors.white;
    final sign = isIncome ? '+' : '-';
    final amountStr = '$sign${AppConstants.currencySymbol}${_formatAmount(transaction.amount)}';

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(transaction.date);
    } catch (_) {
      parsedDate = null;
    }

    final now = DateTime.now();
    String dateStr;
    if (parsedDate != null) {
      if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
        dateStr = 'Today , ${DateFormat('HH:mm').format(parsedDate)}';
      } else {
        dateStr = DateFormat('d MMM , HH:mm').format(parsedDate);
      }
    } else {
      dateStr = transaction.date;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Circular Avatar Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isIncome ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  AppConstants.categoryIcon(transaction.category),
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppConstants.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing Amount
            Text(
              amountStr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),

            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 4),
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
                      child: Text('Delete', style: TextStyle(color: AppConstants.expenseColor)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }
}
