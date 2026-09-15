// Comprehensive smoke & theme test for Finance Tracker app in Slice UPI Dark Mode
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/main.dart';
import 'package:finance_tracker/utils/constants.dart';
import 'package:finance_tracker/screens/dashboard_screen.dart';
import 'package:finance_tracker/screens/transactions_screen.dart';
import 'package:finance_tracker/screens/budgets_screen.dart';
import 'package:finance_tracker/screens/reports_screen.dart';
import 'package:finance_tracker/widgets/summary_card.dart';

void main() {
  test('Theme constants match neo-banking specifications', () {
    expect(AppConstants.primaryColor, Colors.white);
    expect(AppConstants.secondaryColor, const Color(0xFF2C2C32));
    expect(AppConstants.plumColor, const Color(0xFF1F1F24));
    expect(AppConstants.backgroundColor, const Color(0xFF070709));
    expect(AppConstants.textPrimary, const Color(0xFFFFFFFF));
    expect(AppConstants.incomeColor, const Color(0xFF00E676));
    expect(AppConstants.expenseColor, const Color(0xFFFF453A));
  });

  testWidgets('App launches with Slice UPI Dark Theme and 4 navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceTrackerApp());
    expect(find.byType(FinanceTrackerApp), findsOneWidget);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);
    expect(materialApp.theme?.scaffoldBackgroundColor, AppConstants.backgroundColor);
    expect(materialApp.theme?.colorScheme.primary, AppConstants.primaryColor);

    // Verify 4 navigation tabs (Goals removed)
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Goals'), findsNothing);
  });

  testWidgets('SummaryCard renders high contrast text in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryCard(
            label: 'Total Balance',
            amount: '₹50,000',
            icon: Icons.account_balance_wallet,
            color: AppConstants.primaryColor,
            isWide: false,
          ),
        ),
      ),
    );

    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('₹50,000'), findsOneWidget);

    final amountText = tester.widget<Text>(find.text('₹50,000'));
    // Amount must be crisp white on dark card
    expect(amountText.style?.color, AppConstants.textPrimary);
  });

  testWidgets('Remaining screens instantiate without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardScreen(),
        ),
      ),
    );
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TransactionsScreen(),
        ),
      ),
    );
    expect(find.byType(TransactionsScreen), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetsScreen(),
        ),
      ),
    );
    expect(find.byType(BudgetsScreen), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportsScreen(),
        ),
      ),
    );
    expect(find.byType(ReportsScreen), findsOneWidget);
  });
}
