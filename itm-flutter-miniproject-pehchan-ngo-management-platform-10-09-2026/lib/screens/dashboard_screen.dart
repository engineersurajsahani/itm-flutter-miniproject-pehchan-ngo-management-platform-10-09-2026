import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _income = 0;
  double _expenses = 0;
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;
  Timer? _snackBarTimer;

  final DateTime _now = DateTime.now();
  String get _currentMonth => DateFormat('yyyy-MM').format(_now);

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.transactionNotifier.addListener(_onExternalUpdate);
    _loadData();
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    DatabaseHelper.instance.transactionNotifier.removeListener(_onExternalUpdate);
    super.dispose();
  }

  void _onExternalUpdate() {
    if (mounted) _loadData(silent: true);
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final income = await DatabaseHelper.instance
          .getMonthlyTotal(_currentMonth, AppConstants.income);
      final expenses = await DatabaseHelper.instance
          .getMonthlyTotal(_currentMonth, AppConstants.expense);
      final recent =
          await DatabaseHelper.instance.getRecentTransactions(5);

      if (mounted) {
        setState(() {
          _income = income;
          _expenses = expenses;
          _recentTransactions = recent;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  String _fmt(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  void _openTransactionDetail(TransactionModel t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          transaction: t,
          onDeleted: () => _loadData(silent: true),
          onUpdated: () => _loadData(silent: true),
        ),
      ),
    );
  }

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.neoCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.white),
              title: const Text('INR Personal Account', style: TextStyle(color: Colors.white)),
              subtitle: Text('Current Balance: ${AppConstants.currencySymbol}${_fmt(_income - _expenses)}',
                  style: const TextStyle(color: AppConstants.textMuted)),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Export Statement', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statement exported')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _income - _expenses;

    return Scaffold(
      backgroundColor: AppConstants.neoBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                color: Colors.white,
                backgroundColor: AppConstants.surfaceElevated,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // 1. Top App Bar (Avatar, Search Pill, Action Buttons)
                      _buildTopBar(),

                      const SizedBox(height: 24),

                      // 2. Hero Balance Section (USD Personal, $12,386.40, Dots & Manage)
                      _buildBalanceHero(balance),

                      const SizedBox(height: 28),

                      // 3. Circular Quick Actions (Top up, Move, Details, More)
                      _buildQuickActions(),

                      const SizedBox(height: 32),

                      // 4. Operations (Recent Transactions) Grouped Card
                      _buildOperationsSection(),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 1. Top Bar matching Image 1: Avatar | Search Pill | Action Buttons
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // Circular Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.neoPill,
              border: Border.all(color: AppConstants.neoPillBorder, width: 1.2),
            ),
            child: const Center(
              child: Text(
                '👤',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search Pill
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppConstants.neoPill,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppConstants.neoPillBorder, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppConstants.textMuted, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Search',
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Action 1: Analytics / Reports Icon Button
          _buildPillIconButton(
            icon: Icons.bar_chart_rounded,
            tooltip: 'Reports',
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(3); // Navigate to Reports
              }
            },
          ),
          const SizedBox(width: 8),

          // Action 2: Card / Budgets Icon Button
          _buildPillIconButton(
            icon: Icons.credit_card_rounded,
            tooltip: 'Budgets',
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(2); // Navigate to Budgets
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppConstants.neoPill,
          shape: BoxShape.circle,
          border: Border.all(color: AppConstants.neoPillBorder, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // 2. Hero Balance Section matching Image 1
  Widget _buildBalanceHero(double balance) {
    return Column(
      children: [
        const Text(
          'INR Personal',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppConstants.textMuted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${AppConstants.currencySymbol}${_fmt(balance)}',
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // Dots & Manage Pill
        InkWell(
          onTap: _showManageSheet,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.neoPill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.neoPillBorder, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Carousel dots
                Text(
                  '• • •',
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Manage',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: AppConstants.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Circular Quick Actions Row matching Image 1
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.add,
            label: 'Top up',
            onTap: () async {
              final res = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(initialType: AppConstants.income),
                ),
              );
              if (res == true) _loadData();
            },
          ),
          _buildCircleButton(
            icon: Icons.north_east_rounded,
            label: 'Move',
            onTap: () async {
              final res = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(initialType: AppConstants.expense),
                ),
              );
              if (res == true) _loadData();
            },
          ),
          _buildCircleButton(
            icon: Icons.description_outlined,
            label: 'Details',
            onTap: () {
              if (widget.onTabChange != null) {
                widget.onTabChange!(1); // Go to Transactions
              }
            },
          ),
          _buildCircleButton(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            onTap: _showManageSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Operations Grouped Card matching Image 1
  Widget _buildOperationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          // Header: Operations | All >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Operations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  if (widget.onTabChange != null) {
                    widget.onTabChange!(1); // Go to Transactions
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.neoPill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.neoPillBorder, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: AppConstants.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grouped Card Container
          Container(
            decoration: BoxDecoration(
              color: AppConstants.neoCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.neoCardBorder, width: 1),
            ),
            child: _recentTransactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No operations yet',
                        style: TextStyle(color: AppConstants.textMuted),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(_recentTransactions.length, (index) {
                      final txn = _recentTransactions[index];
                      final isLast = index == _recentTransactions.length - 1;
                      return Column(
                        children: [
                          TransactionTile(
                            transaction: txn,
                            isLast: isLast,
                            onTap: () => _openTransactionDetail(txn),
                          ),
                          if (!isLast)
                            const Divider(
                              color: AppConstants.neoCardBorder,
                              height: 1,
                              indent: 70,
                              endIndent: 14,
                            ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}
