import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../widgets/category_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isMonthly = true;

  // Monthly report state
  late DateTime _selectedMonth;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;
  Map<String, double> _categorySpending = {};
  int _transactionCount = 0;

  // Yearly report state
  late int _selectedYear;
  double _yearlyIncome = 0;
  double _yearlyExpense = 0;
  List<Map<String, double>> _monthlyBreakdown = List.generate(
      12, (_) => {'income': 0, 'expense': 0});

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _selectedYear = DateTime.now().year;
    DatabaseHelper.instance.transactionNotifier.addListener(_onExternalUpdate);
    _loadMonthlyData();
  }

  @override
  void dispose() {
    DatabaseHelper.instance.transactionNotifier.removeListener(_onExternalUpdate);
    super.dispose();
  }

  void _onExternalUpdate() {
    if (mounted) {
      if (_isMonthly) {
        _loadMonthlyData(silent: true);
      } else {
        _loadYearlyData(silent: true);
      }
    }
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);
  String get _yearKey => _selectedYear.toString();

  Future<void> _loadMonthlyData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final income = await DatabaseHelper.instance
          .getMonthlyTotal(_monthKey, AppConstants.income);
      final expense = await DatabaseHelper.instance
          .getMonthlyTotal(_monthKey, AppConstants.expense);
      final spending =
          await DatabaseHelper.instance.getCategorySpending(_monthKey);
      final txns =
          await DatabaseHelper.instance.getTransactionsByMonth(_monthKey);

      if (mounted) {
        setState(() {
          _monthlyIncome = income;
          _monthlyExpense = expense;
          _categorySpending = spending;
          _transactionCount = txns.length;
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

  Future<void> _loadYearlyData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final income = await DatabaseHelper.instance
          .getYearlyTotal(_yearKey, AppConstants.income);
      final expense = await DatabaseHelper.instance
          .getYearlyTotal(_yearKey, AppConstants.expense);
      final breakdown =
          await DatabaseHelper.instance.getMonthlyBreakdown(_yearKey);

      if (mounted) {
        setState(() {
          _yearlyIncome = income;
          _yearlyExpense = expense;
          _monthlyBreakdown = breakdown;
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

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
          _selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadMonthlyData();
  }

  void _changeYear(int delta) {
    setState(() => _selectedYear += delta);
    _loadYearlyData();
  }

  String _fmt(double amount) {
    return NumberFormat('#,##,##0', 'en_IN').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented tab toggle in Slice style
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.cardBorderColor, width: 1),
            ),
            child: Row(
              children: [
                _toggleButton('Monthly', _isMonthly, () {
                  setState(() => _isMonthly = true);
                  _loadMonthlyData();
                }),
                _toggleButton('Yearly', !_isMonthly, () {
                  setState(() => _isMonthly = false);
                  _loadYearlyData();
                }),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _isMonthly
                    ? _buildMonthlyReport()
                    : _buildYearlyReport(),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : AppConstants.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyReport() {
    final balance = _monthlyIncome - _monthlyExpense;
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final highestCategory =
        sortedCategories.isNotEmpty ? sortedCategories.first.key : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: Colors.white,
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: Colors.white,
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary cards
          _reportCard(
            'Total Income',
            '${AppConstants.currencySymbol}${_fmt(_monthlyIncome)}',
            AppConstants.incomeColor,
            Icons.arrow_downward,
          ),
          const SizedBox(height: 8),
          _reportCard(
            'Total Expenses',
            '${AppConstants.currencySymbol}${_fmt(_monthlyExpense)}',
            AppConstants.expenseColor,
            Icons.arrow_upward,
          ),
          const SizedBox(height: 8),
          _reportCard(
            'Net Balance',
            '${AppConstants.currencySymbol}${_fmt(balance)}',
            balance >= 0 ? AppConstants.incomeColor : AppConstants.expenseColor,
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Transactions',
                  '$_transactionCount',
                  Icons.receipt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Highest Category',
                  highestCategory,
                  AppConstants.categoryIcon(highestCategory),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category breakdown
          if (_categorySpending.isNotEmpty) ...[
            const Text(
              'Top Expense Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...sortedCategories.map((entry) => _categoryRow(
                entry.key, entry.value, _monthlyExpense)),
            const SizedBox(height: 20),

            // Pie chart
            const Text(
              'Expense Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.cardBorderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CategoryPieChart(categoryData: _categorySpending),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline,
                      size: 60, color: AppConstants.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No expense data for this month',
                    style: TextStyle(color: AppConstants.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearlyReport() {
    final savings = _yearlyIncome - _yearlyExpense;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: Colors.white,
                onPressed: () => _changeYear(-1),
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: Colors.white,
                onPressed: () => _changeYear(1),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _reportCard(
            'Annual Income',
            '${AppConstants.currencySymbol}${_fmt(_yearlyIncome)}',
            AppConstants.incomeColor,
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _reportCard(
            'Annual Expenses',
            '${AppConstants.currencySymbol}${_fmt(_yearlyExpense)}',
            AppConstants.expenseColor,
            Icons.trending_down,
          ),
          const SizedBox(height: 8),
          _reportCard(
            'Annual Savings',
            '${AppConstants.currencySymbol}${_fmt(savings)}',
            savings >= 0 ? AppConstants.incomeColor : AppConstants.expenseColor,
            Icons.savings,
          ),
          const SizedBox(height: 20),

          // Monthly bar chart
          const Text(
            'Monthly Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.cardBorderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: YearlyBarChart(monthlyData: _monthlyBreakdown),
          ),
          const SizedBox(height: 20),

          // Monthly detail list
          const Text(
            'Month-by-Month Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 12),
          ...List.generate(12, (i) {
            final income = _monthlyBreakdown[i]['income'] ?? 0;
            final expense = _monthlyBreakdown[i]['expense'] ?? 0;
            final net = income - expense;
            if (income == 0 && expense == 0) return const SizedBox();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.cardBorderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    months[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat(
                          'Income', '${AppConstants.currencySymbol}${_fmt(income)}', AppConstants.incomeColor),
                      _miniStat('Expenses', '${AppConstants.currencySymbol}${_fmt(expense)}',
                          AppConstants.expenseColor),
                      _miniStat(
                          'Net',
                          '${AppConstants.currencySymbol}${_fmt(net)}',
                          net >= 0
                              ? AppConstants.incomeColor
                              : AppConstants.expenseColor),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _reportCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 14, color: AppConstants.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(String category, double amount, double total) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    final color = AppConstants.categoryColor(category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(AppConstants.categoryIcon(category),
                color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: AppConstants.textPrimary)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: AppConstants.neoPill,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppConstants.currencySymbol}${_fmt(amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
