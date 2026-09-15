import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:finance_tracker/database/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/utils/constants.dart';
import 'package:finance_tracker/screens/transactions_screen.dart';
import 'package:finance_tracker/screens/transaction_detail_screen.dart';
import 'package:finance_tracker/widgets/transaction_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Transaction Delete & Revert Back Unit Tests', () {
    final dbHelper = DatabaseHelper.instance;

    test('Deleting an Expense reverts expense total and net balance', () async {
      final initialExpense = await dbHelper.getTotalExpense();

      // 1. Insert an Expense
      final notifierBefore = dbHelper.transactionNotifier.value;
      final expense = TransactionModel(
        title: 'Grocery Shopping',
        amount: 2500.0,
        type: AppConstants.expense,
        category: 'Food',
        date: '2026-09-12',
        note: 'Supermarket visit',
      );
      final expenseId = await dbHelper.insertTransaction(expense);
      expect(expenseId, isPositive);
      expect(dbHelper.transactionNotifier.value, notifierBefore + 1);

      // Verify expense added
      var currentExpense = await dbHelper.getTotalExpense();
      expect(currentExpense, initialExpense + 2500.0);

      // 2. Delete the Expense (reverting the expense back)
      final allBeforeDelete = await dbHelper.getAllTransactions();
      final deletedTx = allBeforeDelete.firstWhere((t) => t.id == expenseId);
      final deleteResult = await dbHelper.deleteTransaction(expenseId);
      expect(deleteResult, 1);
      expect(dbHelper.transactionNotifier.value, notifierBefore + 2);

      // Totals should revert back to original
      currentExpense = await dbHelper.getTotalExpense();
      expect(currentExpense, initialExpense);

      // 3. Revert / Undo the deletion
      final restoredId = await dbHelper.insertTransaction(deletedTx);
      expect(restoredId, expenseId); // Confirms ID preservation on revert
      expect(dbHelper.transactionNotifier.value, notifierBefore + 3);

      // Totals reflect restored expense
      currentExpense = await dbHelper.getTotalExpense();
      expect(currentExpense, initialExpense + 2500.0);

      // Cleanup
      await dbHelper.deleteTransaction(expenseId);
    });

    test('Deleting an Income reverts income total and net balance', () async {
      final initialIncome = await dbHelper.getTotalIncome();

      // 1. Insert an Income
      final income = TransactionModel(
        title: 'Bonus Payout',
        amount: 8000.0,
        type: AppConstants.income,
        category: 'Salary',
        date: '2026-09-14',
        note: 'Performance bonus',
      );
      final incomeId = await dbHelper.insertTransaction(income);
      expect(incomeId, isPositive);

      // Verify income added
      var currentIncome = await dbHelper.getTotalIncome();
      expect(currentIncome, initialIncome + 8000.0);

      // 2. Delete the Income (reverting the income back)
      final allBeforeDelete = await dbHelper.getAllTransactions();
      final deletedTx = allBeforeDelete.firstWhere((t) => t.id == incomeId);
      final deleteResult = await dbHelper.deleteTransaction(incomeId);
      expect(deleteResult, 1);

      // Totals should revert back to original
      currentIncome = await dbHelper.getTotalIncome();
      expect(currentIncome, initialIncome);

      // 3. Revert / Undo the deletion
      final restoredId = await dbHelper.insertTransaction(deletedTx);
      expect(restoredId, incomeId);

      // Totals reflect restored income
      currentIncome = await dbHelper.getTotalIncome();
      expect(currentIncome, initialIncome + 8000.0);

      // Cleanup
      await dbHelper.deleteTransaction(incomeId);
    });
  });

  group('TransactionsScreen Widget Tests', () {
    final dbHelper = DatabaseHelper.instance;

    setUp(() async {
      await dbHelper.insertTransaction(TransactionModel(
        title: 'Tech Salary',
        amount: 50000.0,
        type: AppConstants.income,
        category: 'Salary',
        date: '2026-09-01',
      ));
      await dbHelper.insertTransaction(TransactionModel(
        title: 'Office Commute',
        amount: 1500.0,
        type: AppConstants.expense,
        category: 'Transport',
        date: '2026-09-05',
      ));
    });

    testWidgets('Renders TransactionsScreen with summary card and transaction list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppConstants.backgroundColor,
          ),
          home: const Scaffold(
            body: TransactionsScreen(),
          ),
        ),
      );

      // Allow background SQLite FFI query to complete
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      // Check header and summary card labels
      expect(find.text('Transactions'), findsWidgets);
      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('Total Expenses'), findsOneWidget);

      // If transactions exist, verify Dismissible swipe-to-delete widgets are present
      final dismissibles = find.byType(Dismissible);
      expect(dismissibles, findsWidgets);

      // Verify Dismissible has endToStart swipe direction
      final dismissibleWidget = tester.widget<Dismissible>(dismissibles.first);
      expect(dismissibleWidget.direction, DismissDirection.endToStart);
    });

    testWidgets('TransactionTile renders formatted amount and triggers onDelete callback', (WidgetTester tester) async {
      bool deleteTriggered = false;
      bool editTriggered = false;

      final sampleTxn = TransactionModel(
        id: 99,
        title: 'Dinner with Team',
        amount: 3450.0,
        type: AppConstants.expense,
        category: 'Food',
        date: '2026-09-15',
        note: 'Team outing',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppConstants.backgroundColor,
          ),
          home: Scaffold(
            body: TransactionTile(
              transaction: sampleTxn,
              onEdit: () => editTriggered = true,
              onDelete: () => deleteTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Dinner with Team'), findsOneWidget);
      expect(find.text('-₹3,450.00'), findsOneWidget);

      // Tap menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Check popup menu items
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteTriggered, isTrue);
      expect(editTriggered, isFalse);
    });

    testWidgets('TransactionDetailScreen renders merchant, status, and half-year chart', (WidgetTester tester) async {
      final sampleTxn = TransactionModel(
        id: 101,
        title: 'Astra Coffeebar',
        amount: 21.50,
        type: AppConstants.expense,
        category: 'Food',
        date: '2026-09-15 08:32:00',
        note: 'Morning coffee',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: TransactionDetailScreen(transaction: sampleTxn),
        ),
      );

      // Assert merchant header & amount
      expect(find.text('Astra Coffeebar'), findsOneWidget);
      expect(find.text('-₹21.50'), findsOneWidget);

      // Assert status and card info
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('•• 2675'), findsOneWidget);

      // Assert category and analytics
      expect(find.text('Exclude from analytics'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);

      // Assert half-year spending card
      expect(find.text('Half-year spending'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
    });
  });
}
