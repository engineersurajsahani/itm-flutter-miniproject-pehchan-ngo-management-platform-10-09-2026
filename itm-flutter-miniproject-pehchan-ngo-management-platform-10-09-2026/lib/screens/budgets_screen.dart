import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/budget_model.dart';
import '../utils/constants.dart';
import '../widgets/budget_card.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<BudgetModel> _budgets = [];
  Map<String, double> _categorySpending = {};
  bool _isLoading = true;

  // Current selected month for budgets
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    DatabaseHelper.instance.transactionNotifier.addListener(_onExternalUpdate);
    _loadData();
  }

  @override
  void dispose() {
    DatabaseHelper.instance.transactionNotifier.removeListener(_onExternalUpdate);
    super.dispose();
  }

  void _onExternalUpdate() {
    if (mounted) _loadData(silent: true);
  }

  String get _monthKey =>
      DateFormat('yyyy-MM').format(_selectedMonth);

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final budgets =
          await DatabaseHelper.instance.getBudgetsByMonth(_monthKey);
      final spending =
          await DatabaseHelper.instance.getCategorySpending(_monthKey);
      if (mounted) {
        setState(() {
          _budgets = budgets;
          _categorySpending = spending;
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

  Future<void> _showAddEditDialog({BudgetModel? existing}) async {
    final isEditing = existing != null;
    String? selectedCategory = existing?.category;
    final amountController =
        TextEditingController(text: existing?.amount.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    // Determine which categories already have budgets this month (to avoid dupes)
    final usedCategories =
        _budgets.map((b) => b.category).toSet();
    final available = AppConstants.expenseCategories
        .where((c) => !usedCategories.contains(c) || c == existing?.category)
        .toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.cardBorderColor, width: 1.2),
          ),
          title: Text(
            isEditing ? 'Edit Budget' : 'Create Budget',
            style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  dropdownColor: AppConstants.surfaceElevated,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppConstants.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppConstants.cardBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppConstants.cardBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: const Text('Select category', style: TextStyle(color: AppConstants.textMuted)),
                  items: available.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(AppConstants.categoryIcon(c),
                              color: AppConstants.categoryColor(c), size: 18),
                          const SizedBox(width: 8),
                          Text(c, style: const TextStyle(color: AppConstants.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCategory = v),
                  validator: (v) =>
                      v == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 14),
                const Text('Budget Amount (${AppConstants.currencySymbol})',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: amountController,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppConstants.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppConstants.cardBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppConstants.cardBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    hintText: 'e.g. 5000',
                    hintStyle: const TextStyle(color: AppConstants.textMuted),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixText: '${AppConstants.currencySymbol} ',
                    prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount cannot be empty';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Please enter a valid amount';
                    if (n <= 0) return 'Amount must be greater than 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final budget = BudgetModel(
                  id: existing?.id,
                  category: selectedCategory!,
                  amount: double.parse(amountController.text.trim()),
                  month: _monthKey,
                );
                if (isEditing) {
                  await DatabaseHelper.instance.updateBudget(budget);
                } else {
                  await DatabaseHelper.instance.insertBudget(budget);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isEditing ? 'Update' : 'Create', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBudget(BudgetModel b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.cardBorderColor, width: 1.2),
        ),
        title: const Text('Delete Budget?', style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to delete this budget?', style: TextStyle(color: AppConstants.textSecondary)),
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
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteBudget(b.id!);
      _loadData();
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Budgets', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _monthSelector(),
                Expanded(
                  child: _budgets.isEmpty ? _emptyState() : _buildBudgetList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budgets_fab',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Budget', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  Widget _monthSelector() {
    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.neoBackground,
        border: Border(
          bottom: BorderSide(
            color: AppConstants.neoCardBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList() {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppConstants.surfaceElevated,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _budgets.length,
        itemBuilder: (ctx, i) {
          final budget = _budgets[i];
          final spent = _categorySpending[budget.category] ?? 0.0;
          return BudgetCard(
            budget: budget,
            spent: spent,
            onEdit: () => _showAddEditDialog(existing: budget),
            onDelete: () => _deleteBudget(budget),
          );
        },
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
            Icon(Icons.account_balance_wallet,
                size: 72, color: AppConstants.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No budgets created',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a budget to start monitoring your spending.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Create Budget', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
