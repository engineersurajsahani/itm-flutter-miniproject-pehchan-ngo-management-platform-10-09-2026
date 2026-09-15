import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  Timer? _snackBarTimer;

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.transactionNotifier.addListener(_onExternalUpdate);
    _loadTransactions();
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    DatabaseHelper.instance.transactionNotifier.removeListener(_onExternalUpdate);
    super.dispose();
  }

  void _onExternalUpdate() {
    if (mounted) _loadTransactions(silent: true);
  }

  Future<void> _loadTransactions({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getAllTransactions();
      if (mounted) {
        setState(() {
          _transactions = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == AppConstants.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpenses => _transactions
      .where((t) => t.type == AppConstants.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _netBalance => _totalIncome - _totalExpenses;

  String _fmt(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  void _openTransactionDetail(TransactionModel t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          transaction: t,
          onDeleted: () => _loadTransactions(silent: true),
          onUpdated: () => _loadTransactions(silent: true),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel t) async {
    final confirmed = await _showDeleteDialog(
      'Delete ${t.type}?',
      'Are you sure you want to delete "${t.title}" (${AppConstants.currencySymbol}${_fmt(t.amount)})?\n\nThis amount will be reverted back from your totals.',
    );
    if (confirmed) {
      await _executeDelete(t);
    }
  }

  Future<void> _executeDelete(TransactionModel t) async {
    try {
      await DatabaseHelper.instance.deleteTransaction(t.id!);
      await _loadTransactions(silent: true);
      if (mounted) {
        _snackBarTimer?.cancel();
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();

        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${t.type} deleted: ${t.title} (${AppConstants.currencySymbol}${_fmt(t.amount)})',
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
              textColor: AppConstants.primaryColor,
              onPressed: () async {
                _snackBarTimer?.cancel();
                // Revert back: re-insert the deleted transaction
                await DatabaseHelper.instance.insertTransaction(t);
                await _loadTransactions(silent: true);
                if (mounted) {
                  messenger.clearSnackBars();
                  final revertController = messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${t.type} "${t.title}" reverted back!',
                        style: const TextStyle(color: AppConstants.textPrimary),
                      ),
                      backgroundColor: AppConstants.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  _snackBarTimer = Timer(const Duration(seconds: 3), () {
                    revertController.close();
                  });
                }
              },
            ),
          ),
        );

        // Explicitly dismiss after 5 seconds regardless of cursor hover/platform behavior
        _snackBarTimer = Timer(const Duration(seconds: 5), () {
          controller.close();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction. Please try again.')),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.cardBorderColor, width: 1.2),
        ),
        title: Text(title, style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppConstants.textSecondary)),
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
    return result == true;
  }

  // Group transactions by month for display
  Map<String, List<TransactionModel>> _groupByMonth() {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in _transactions) {
      String monthKey;
      try {
        final date = DateTime.parse(t.date);
        monthKey = DateFormat('MMMM yyyy').format(date);
      } catch (_) {
        monthKey = 'Unknown';
      }
      grouped.putIfAbsent(monthKey, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            tooltip: 'Add Transaction',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen()),
              );
              if (result == true) _loadTransactions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _transactions.isEmpty
              ? _emptyState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final grouped = _groupByMonth();
    final months = grouped.keys.toList();

    return RefreshIndicator(
      color: AppConstants.primaryColor,
      backgroundColor: AppConstants.surfaceElevated,
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: months.length + 1, // +1 for the summary header card
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return _buildSummaryCard();
          }

          final month = months[i - 1];
          final txns = grouped[month]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${txns.length} ${txns.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ...txns.map((t) => Dismissible(
                    key: ValueKey('txn_${t.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _showDeleteDialog(
                      'Delete ${t.type}?',
                      'Are you sure you want to delete "${t.title}" (${AppConstants.currencySymbol}${_fmt(t.amount)})?\n\nThis amount will be reverted back from your totals.',
                    ),
                    onDismissed: (_) => _executeDelete(t),
                    background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppConstants.expenseColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: TransactionTile(
                      transaction: t,
                      onTap: () => _openTransactionDetail(t),
                      onEdit: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AddTransactionScreen(existing: t)),
                        );
                        if (result == true) _loadTransactions();
                      },
                      onDelete: () => _deleteTransaction(t),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppConstants.neoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.neoCardBorder, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstants.currencySymbol}${_fmt(_netBalance)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.neoPill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.neoPillBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_transactions.length} Transactions',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: AppConstants.cardBorderColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppConstants.incomeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_downward, color: AppConstants.incomeColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Income', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '+${AppConstants.currencySymbol}${_fmt(_totalIncome)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.incomeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: AppConstants.cardBorderColor),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppConstants.expenseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_upward, color: AppConstants.expenseColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Expenses', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '-${AppConstants.currencySymbol}${_fmt(_totalExpenses)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.expenseColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 72, color: AppConstants.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first transaction to start tracking your finances.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen()),
                );
                if (result == true) _loadTransactions();
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
