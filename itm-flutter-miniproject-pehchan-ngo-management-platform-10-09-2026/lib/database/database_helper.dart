import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final DatabaseFactory dbFactory;
    final String path;

    if (kIsWeb) {
      dbFactory = databaseFactoryFfiWeb;
      path = 'finance_tracker.db';
    } else {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux ||
           defaultTargetPlatform == TargetPlatform.windows)) {
        sqfliteFfiInit();
        dbFactory = databaseFactoryFfi;
      } else {
        dbFactory = databaseFactory;
      }
      final dbPath = await dbFactory.getDatabasesPath();
      path = join(dbPath, 'finance_tracker.db');
    }

    return await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createTables,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
            await db.delete('transactions');
            await db.delete('budgets');
            await db.delete('goals');
            await _insertDemoData(db);
          }
        },
      ),
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        targetDate TEXT
      )
    ''');

    // Insert demo data on first launch
    await _insertDemoData(db);
  }

  // Insert initial data: starts with $100,000 income and expenses
  Future<void> _insertDemoData(Database db) async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');

    // Sample transactions: $100,000 income + expenses
    final transactions = [
      {
        'title': 'Monthly Salary',
        'amount': 100000.0,
        'type': 'Income',
        'category': 'Salary',
        'date': '$year-$month-01',
        'note': 'Primary monthly salary',
      },
      {
        'title': 'Apartment Rent',
        'amount': 20000.0,
        'type': 'Expense',
        'category': 'Bills',
        'date': '$year-$month-02',
        'note': 'Monthly house rent',
      },
      {
        'title': 'Groceries & Supermarket',
        'amount': 8500.0,
        'type': 'Expense',
        'category': 'Food',
        'date': '$year-$month-04',
        'note': 'Monthly groceries & supplies',
      },
      {
        'title': 'Electricity & High-Speed Wi-Fi',
        'amount': 3200.0,
        'type': 'Expense',
        'category': 'Bills',
        'date': '$year-$month-05',
        'note': 'Utilities',
      },
      {
        'title': 'Fuel & Commute',
        'amount': 5400.0,
        'type': 'Expense',
        'category': 'Transport',
        'date': '$year-$month-06',
        'note': 'Fuel & transit',
      },
      {
        'title': 'Dining Out & Cafe',
        'amount': 4200.0,
        'type': 'Expense',
        'category': 'Food',
        'date': '$year-$month-08',
        'note': 'Weekend dinner with family',
      },
      {
        'title': 'Shopping & Clothing',
        'amount': 6000.0,
        'type': 'Expense',
        'category': 'Shopping',
        'date': '$year-$month-09',
        'note': 'Wardrobe & essentials',
      },
    ];

    for (final t in transactions) {
      await db.insert('transactions', t);
    }

    // Sample budgets tailored for $100,000 scale
    final budgets = [
      {'category': 'Bills', 'amount': 32000.0, 'month': currentMonth},
      {'category': 'Food', 'amount': 15000.0, 'month': currentMonth},
      {'category': 'Transport', 'amount': 10000.0, 'month': currentMonth},
      {'category': 'Shopping', 'amount': 10000.0, 'month': currentMonth},
      {'category': 'Entertainment', 'amount': 8000.0, 'month': currentMonth},
    ];

    for (final b in budgets) {
      await db.insert('budgets', b);
    }

    // Sample savings goal
    await db.insert('goals', {
      'name': 'Emergency Fund',
      'targetAmount': 200000.0,
      'currentAmount': 65000.0,
      'targetDate': '${now.year}-12-31',
    });
  }

  final ValueNotifier<int> transactionNotifier = ValueNotifier<int>(0);

  // ============================================================
  // TRANSACTION CRUD
  // ============================================================

  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    final map = t.toMap();
    if (t.id == null) {
      map.remove('id');
    }
    final id = await db.insert(
      'transactions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    transactionNotifier.value++;
    return id;
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(String month) async {
    // month format: 'yyyy-MM'
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$month%'],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByYear(String year) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$year%'],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions(int limit) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<int> updateTransaction(TransactionModel t) async {
    final db = await database;
    final res = await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
    transactionNotifier.value++;
    return res;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final res = await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    transactionNotifier.value++;
    return res;
  }

  // Overall income/expense totals
  Future<double> getTotalByType(String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [type],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalIncome() => getTotalByType('Income');
  Future<double> getTotalExpense() => getTotalByType('Expense');

  // Monthly income/expense totals
  Future<double> getMonthlyTotal(String month, String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date LIKE ? AND type = ?',
      ['$month%', type],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Category spending for a given month
  Future<Map<String, double>> getCategorySpending(String month) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT category, SUM(amount) as total 
         FROM transactions 
         WHERE date LIKE ? AND type = 'Expense'
         GROUP BY category''',
      ['$month%'],
    );
    final Map<String, double> map = {};
    for (final row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  // Yearly income/expense totals
  Future<double> getYearlyTotal(String year, String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date LIKE ? AND type = ?',
      ['$year%', type],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Monthly breakdown for yearly report (12 months)
  Future<List<Map<String, double>>> getMonthlyBreakdown(String year) async {
    final db = await database;
    final List<Map<String, double>> breakdown = [];
    for (int m = 1; m <= 12; m++) {
      final monthStr = '$year-${m.toString().padLeft(2, '0')}';
      final incomeResult = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE date LIKE ? AND type = 'Income'",
        ['$monthStr%'],
      );
      final expenseResult = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE date LIKE ? AND type = 'Expense'",
        ['$monthStr%'],
      );
      breakdown.add({
        'income': (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0,
        'expense': (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0,
      });
    }
    return breakdown;
  }

  // ============================================================
  // BUDGET CRUD
  // ============================================================

  Future<int> insertBudget(BudgetModel b) async {
    final db = await database;
    return await db.insert('budgets', b.toMap()..remove('id'));
  }

  Future<List<BudgetModel>> getBudgetsByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<int> updateBudget(BudgetModel b) async {
    final db = await database;
    return await db.update(
      'budgets',
      b.toMap(),
      where: 'id = ?',
      whereArgs: [b.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // GOAL CRUD
  // ============================================================

  Future<int> insertGoal(GoalModel g) async {
    final db = await database;
    return await db.insert('goals', g.toMap()..remove('id'));
  }

  Future<List<GoalModel>> getAllGoals() async {
    final db = await database;
    final maps = await db.query('goals', orderBy: 'id DESC');
    return maps.map((m) => GoalModel.fromMap(m)).toList();
  }

  Future<int> updateGoal(GoalModel g) async {
    final db = await database;
    return await db.update(
      'goals',
      g.toMap(),
      where: 'id = ?',
      whereArgs: [g.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
