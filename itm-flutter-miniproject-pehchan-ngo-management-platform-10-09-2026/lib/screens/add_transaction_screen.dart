import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing; // if provided, we are editing
  final String? initialType;        // 'Income' or 'Expense'

  const AddTransactionScreen({super.key, this.existing, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = AppConstants.expense;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existing!;
      _type = t.type;
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _selectedCategory = t.category;
      try {
        _selectedDate = DateTime.parse(t.date);
      } catch (_) {}
    } else {
      if (widget.initialType != null) {
        _type = widget.initialType!;
      }
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    return _type == AppConstants.income
        ? AppConstants.incomeCategories
        : AppConstants.expenseCategories;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0.')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionModel(
        id: widget.existing?.id,
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _selectedCategory!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateTransaction(transaction);
      } else {
        await DatabaseHelper.instance.insertTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '$_type updated successfully'
                : '$_type added successfully'),
            backgroundColor: _type == AppConstants.income
                ? AppConstants.incomeColor
                : AppConstants.expenseColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaction' : (_type == AppConstants.income ? 'Add Income' : 'Add Expense'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              _sectionLabel('Transaction Type'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.cardBorderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _typeButton(AppConstants.income, Icons.arrow_downward,
                        AppConstants.incomeColor),
                    _typeButton(AppConstants.expense, Icons.arrow_upward,
                        AppConstants.expenseColor),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Title
              _sectionLabel('Title'),
              const SizedBox(height: 8),
              _textField(
                controller: _titleController,
                hint: 'e.g. Grocery Shopping',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 18),

              // Amount
              _sectionLabel('Amount (${AppConstants.currencySymbol})'),
              const SizedBox(height: 8),
              _textField(
                controller: _amountController,
                hint: 'e.g. 500',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount cannot be empty';
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Please enter a valid amount';
                  if (n <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Category
              _sectionLabel('Category'),
              const SizedBox(height: 8),
              _categoryDropdown(),
              const SizedBox(height: 18),

              // Date
              _sectionLabel('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('d MMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, color: AppConstants.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: AppConstants.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Note (optional)
              _sectionLabel('Note (Optional)'),
              const SizedBox(height: 8),
              _textField(
                controller: _noteController,
                hint: 'Add a note...',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Transaction' : 'Add Transaction',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppConstants.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _typeButton(String type, IconData icon, Color color) {
    final isSelected = _type == type;
    final activeTextColor = type == AppConstants.income ? Colors.black : Colors.white;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            final cats = type == AppConstants.income
                ? AppConstants.incomeCategories
                : AppConstants.expenseCategories;
            if (_selectedCategory == null || !cats.contains(_selectedCategory)) {
              _selectedCategory = cats.first;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? activeTextColor : AppConstants.textMuted),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeTextColor : AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppConstants.textPrimary, fontSize: 15),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppConstants.textMuted),
        filled: true,
        fillColor: AppConstants.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.cardBorderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.cardBorderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.expenseColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          dropdownColor: AppConstants.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.textMuted),
          hint: const Text('Select category',
              style: TextStyle(color: AppConstants.textMuted)),
          items: _categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Icon(
                    AppConstants.categoryIcon(cat),
                    color: AppConstants.categoryColor(cat),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(cat, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 15)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }
}
