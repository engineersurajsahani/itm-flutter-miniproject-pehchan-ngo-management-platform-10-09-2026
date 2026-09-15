import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionModel _t;
  bool _excludeFromAnalytics = false;
  Timer? _snackBarTimer;

  // 6 months spending demo data aligned with image
  final List<Map<String, dynamic>> _halfYearData = [
    {'month': 'Jan', 'amount': 140.0, 'height': 0.45},
    {'month': 'Feb', 'amount': 220.0, 'height': 0.70},
    {'month': 'Mar', 'amount': 290.0, 'height': 0.90},
    {'month': 'Apr', 'amount': 250.0, 'height': 0.80},
    {'month': 'May', 'amount': 310.0, 'height': 0.95},
    {'month': 'Jun', 'amount': 190.0, 'height': 0.60},
  ];

  @override
  void initState() {
    super.initState();
    _t = widget.transaction;
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }

  String _fmt(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  String _formatDateTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final timeStr = DateFormat('HH:mm').format(dt);
      if (isToday) {
        return 'Today , $timeStr';
      }
      return DateFormat('d MMM , HH:mm').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.neoCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.neoCardBorder, width: 1.2),
        ),
        title: Text(
          'Delete ${_t.type}?',
          style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${_t.title}" (${AppConstants.currencySymbol}${_fmt(_t.amount)})?\n\nThis will be reverted back from your totals.',
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppConstants.expenseColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deletedTxn = _t;
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      await DatabaseHelper.instance.deleteTransaction(deletedTxn.id!);
      if (widget.onDeleted != null) widget.onDeleted!();

      // Close the detail sheet
      nav.pop(true);

      // Trigger floating revert snackbar on parent
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${deletedTxn.type} deleted: ${deletedTxn.title} (${AppConstants.currencySymbol}${_fmt(deletedTxn.amount)})',
            style: const TextStyle(color: AppConstants.textPrimary),
          ),
          backgroundColor: AppConstants.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppConstants.cardBorderColor),
          ),
          action: SnackBarAction(
            label: 'REVERT',
            textColor: AppConstants.incomeColor,
            onPressed: () async {
              await DatabaseHelper.instance.insertTransaction(deletedTxn);
              messenger.clearSnackBars();
              final revertController = messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '${deletedTxn.type} "${deletedTxn.title}" reverted back!',
                    style: const TextStyle(color: AppConstants.textPrimary),
                  ),
                  backgroundColor: AppConstants.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
              Timer(const Duration(seconds: 3), () => revertController.close());
            },
          ),
        ),
      );

      _snackBarTimer = Timer(const Duration(seconds: 5), () => controller.close());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _t.type == AppConstants.income;
    final amountSign = isIncome ? '+' : '-';
    final amountColor = isIncome ? AppConstants.incomeColor : Colors.white;

    return Scaffold(
      backgroundColor: AppConstants.neoBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.neoBackground,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.neoPill,
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.neoPillBorder, width: 1),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.neoPill,
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.neoPillBorder, width: 1),
              ),
              child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
            ),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: _t)),
              );
              if (updated == true) {
                final all = await DatabaseHelper.instance.getAllTransactions();
                final match = all.firstWhere((item) => item.id == _t.id, orElse: () => _t);
                setState(() => _t = match);
                if (widget.onUpdated != null) widget.onUpdated!();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.neoPill,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppConstants.neoPillBorder, width: 1),
                ),
                child: const Icon(Icons.delete_outline, size: 16, color: AppConstants.expenseColor),
              ),
              onPressed: _handleDelete,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Merchant Emblem / Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  AppConstants.categoryIcon(_t.category),
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Merchant / Title
            Text(
              _t.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Date & Time
            Text(
              _formatDateTime(_t.date),
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textMuted,
              ),
            ),

            const SizedBox(height: 12),

            // Big Amount
            Text(
              '$amountSign${AppConstants.currencySymbol}${_fmt(_t.amount)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: amountColor,
              ),
            ),

            const SizedBox(height: 28),

            // Card 1: Status, Confirmation, Card
            _buildInfoCard([
              _buildRow(
                label: 'Status',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.statusCompletedBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.statusCompletedText.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: AppConstants.statusCompletedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Divider(color: AppConstants.neoCardBorder, height: 24),
              _buildRow(
                label: 'Confirmation',
                trailing: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt downloaded successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Download',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppConstants.neoCardBorder, height: 24),
              _buildRow(
                label: 'Card',
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.credit_card_rounded, size: 16, color: Color(0xFFFF9800)),
                    SizedBox(width: 6),
                    Text(
                      '•• 2675',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 14),

            // Card 2: Analytics & Categorization
            _buildInfoCard([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exclude from analytics',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  Switch.adaptive(
                    value: _excludeFromAnalytics,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppConstants.incomeColor,
                    inactiveTrackColor: AppConstants.neoPill,
                    onChanged: (val) {
                      setState(() => _excludeFromAnalytics = val);
                    },
                  ),
                ],
              ),
              const Divider(color: AppConstants.neoCardBorder, height: 24),
              _buildRow(
                label: 'Category',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppConstants.categoryIcon(_t.category),
                      size: 15,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _t.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppConstants.neoCardBorder, height: 24),
              _buildRow(
                label: 'Amount in analytics',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined, size: 14, color: AppConstants.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${AppConstants.currencySymbol}${_fmt(_t.amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 14),

            // Card 3: Half-year Spending History
            _buildHalfYearSpendingCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConstants.neoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.neoCardBorder, width: 1),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildRow({required String label, required Widget trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildHalfYearSpendingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.neoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.neoCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Half-year spending',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${_fmt(630.96)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Axis labels (200, 0)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${AppConstants.currencySymbol}200', style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                    Text('${AppConstants.currencySymbol}0', style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                  ],
                ),
                const SizedBox(width: 8),

                // Bars with track
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _halfYearData.map((item) {
                      final double ratio = (item['height'] as num).toDouble();
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 18,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppConstants.neoPill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 18,
                              height: 70 * ratio,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['month'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.textMuted,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
