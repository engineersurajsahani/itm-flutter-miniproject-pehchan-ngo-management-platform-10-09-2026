import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'utils/constants.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.windows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          tertiary: AppConstants.plumColor,
          surface: AppConstants.cardColor,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: AppConstants.textPrimary,
          onSurfaceVariant: AppConstants.textSecondary,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        fontFamily: 'Inter',
        fontFamilyFallback: const [
          'Noto Sans',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: AppConstants.backgroundColor,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.cardBorderColor, width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppConstants.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.cardBorderColor, width: 1),
          ),
          titleTextStyle: const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 14,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppConstants.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppConstants.cardBorderColor, width: 1),
          ),
          textStyle: const TextStyle(color: AppConstants.textPrimary),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppConstants.surfaceElevated,
          contentTextStyle: const TextStyle(color: AppConstants.textPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppConstants.cardBorderColor, width: 1),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
        DashboardScreen(onTabChange: (index) => setState(() => _currentIndex = index)),
        const TransactionsScreen(),
        const BudgetsScreen(),
        const ReportsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.neoBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Dock Navigation Bar (Matching Image 1 & 2)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF151518).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF2C2C32), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDockItem(
                      index: 0,
                      label: 'Dashboard',
                      icon: Icons.home_rounded,
                      activeIcon: Icons.home_rounded,
                    ),
                    _buildDockItem(
                      index: 1,
                      label: 'Transactions',
                      icon: Icons.swap_horiz_rounded,
                      activeIcon: Icons.swap_horizontal_circle,
                    ),
                    _buildDockItem(
                      index: 2,
                      label: 'Budgets',
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                    ),
                    _buildDockItem(
                      index: 3,
                      label: 'Reports',
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppConstants.textMuted,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
