import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:finance_tracker/database/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Add income and verify in database', () async {
    final dbHelper = DatabaseHelper.instance;

    final income = TransactionModel(
      title: 'Freelance Design',
      amount: 12000.0,
      type: AppConstants.income,
      category: 'Freelance',
      date: '2026-09-10',
      note: 'Website project',
    );

    final id = await dbHelper.insertTransaction(income);
    expect(id, isPositive);

    final transactions = await dbHelper.getAllTransactions();
    final inserted = transactions.firstWhere((t) => t.id == id);
    expect(inserted.title, 'Freelance Design');
    expect(inserted.amount, 12000.0);
    expect(inserted.type, 'Income');
    expect(inserted.category, 'Freelance');

    final monthlyTotal = await dbHelper.getMonthlyTotal('2026-09', AppConstants.income);
    expect(monthlyTotal, greaterThanOrEqualTo(12000.0));
  });
}
