import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../models/expense.dart';
import '../models/salariedPerson.dart';
import '../models/income.dart';

class ExpenseDbHelper {
  static final ExpenseDbHelper _instance = ExpenseDbHelper._internal();
  static Database? _database;

  factory ExpenseDbHelper() {
    return _instance;
  }

  ExpenseDbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'house_expense.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create expense categories table
    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      )
    ''');

    // Create expense subcategories table
    await db.execute('''
      CREATE TABLE expense_subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        expense_category_id INTEGER NOT NULL,
        FOREIGN KEY(expense_category_id) REFERENCES expense_categories(id)
      )
    ''');

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_subcategory_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY(expense_subcategory_id) REFERENCES expense_subcategories(id)
      )
    ''');

    // Create salaried persons table
    await db.execute('''
      CREATE TABLE salaried_persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Create incomes table
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        salaried_person_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY(salaried_person_id) REFERENCES salaried_persons(id)
      )
    ''');
  }

  // Expense Category operations
  Future<int> insertExpenseCategory(ExpenseCategory category) async {
    final db = await database;
    return await db.insert('expense_categories', category.toMap());
  }

  Future<List<ExpenseCategory>> getAllExpenseCategories() async {
    final db = await database;
    var result = await db.query('expense_categories');
    return result.map((c) => ExpenseCategory.fromMap(c)).toList();
  }

  Future<int> updateExpenseCategory(ExpenseCategory category) async {
    final db = await database;
    return await db.update(
      'expense_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteExpenseCategory(int id) async {
    final db = await database;
    return await db.delete(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense SubCategory operations
  Future<int> insertExpenseSubCategory(ExpenseSubCategory subCategory) async {
    final db = await database;
    return await db.insert('expense_subcategories', subCategory.toMap());
  }

  Future<List<ExpenseSubCategory>> getAllSubCategories() async {
    final db = await database;
    var result = await db.query('expense_subcategories');
    return result.map((sc) => ExpenseSubCategory.fromMap(sc)).toList();
  }

  Future<List<ExpenseSubCategory>> getSubCategoriesForCategory(
      int categoryId) async {
    final db = await database;
    var result = await db.query(
      'expense_subcategories',
      where: 'expense_category_id = ?',
      whereArgs: [categoryId],
    );
    return result.map((sc) => ExpenseSubCategory.fromMap(sc)).toList();
  }

  Future<int> updateExpenseSubCategory(ExpenseSubCategory subCategory) async {
    final db = await database;
    return await db.update(
      'expense_subcategories',
      subCategory.toMap(),
      where: 'id = ?',
      whereArgs: [subCategory.id],
    );
  }

  Future<int> deleteExpenseSubCategory(int id) async {
    final db = await database;
    return await db.delete(
      'expense_subcategories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense operations
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    var result = await db.query('expenses');
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<Map<int, double>> getCurrentMonthExpensesByCategory() async {
    final db = await database;

    // Calculate current month boundaries
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 1);

    // Query to join expenses with subcategories and group by category
    final results = await db.rawQuery('''
      SELECT 
        ec.id as category_id,
        SUM(e.amount) as total_amount
      FROM expenses e
      JOIN expense_subcategories esc ON e.expense_subcategory_id = esc.id
      JOIN expense_categories ec ON esc.expense_category_id = ec.id
      WHERE e.date_time >= ? AND e.date_time < ?
      GROUP BY ec.id
      ORDER BY total_amount DESC
    ''', [firstDayOfMonth.toIso8601String(), lastDayOfMonth.toIso8601String()]);

    // Convert to map of categoryId -> totalAmount
    final Map<int, double> categoryExpenses = {};
    for (final row in results) {
      categoryExpenses[row['category_id'] as int] =
          row['total_amount'] as double;
    }

    return categoryExpenses;
  }

  Future<Map<int, double>> getCurrentMonthExpensesBySubCategory(
      int categoryId) async {
    final db = await database;

    // Calculate current month boundaries
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 1);

    // Query to join expenses with subcategories and filter by category
    final results = await db.rawQuery('''
      SELECT 
        esc.id as subcategory_id,
        SUM(e.amount) as total_amount
      FROM expenses e
      JOIN expense_subcategories esc ON e.expense_subcategory_id = esc.id
      WHERE e.date_time >= ? AND e.date_time < ?
      AND esc.expense_category_id = ?
      GROUP BY esc.id
      ORDER BY total_amount DESC
    ''', [
      firstDayOfMonth.toIso8601String(),
      lastDayOfMonth.toIso8601String(),
      categoryId
    ]);

    // Convert to map of subcategoryId -> totalAmount
    final Map<int, double> subcategoryExpenses = {};
    for (final row in results) {
      subcategoryExpenses[row['subcategory_id'] as int] =
          row['total_amount'] as double;
    }

    return subcategoryExpenses;
  }

  Future<List<Expense>> getLast3MonthsExpenses() async {
    final db = await database;
    final now = DateTime.now();
    final firstDayOfEarliestMonth = DateTime(now.year, now.month - 2, 1);
    final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 1);
    return await db.transaction((txn) async {
      final results = await txn.query(
        'expenses',
        where: 'date_time >= ? AND date_time < ?',
        whereArgs: [
          firstDayOfEarliestMonth.toIso8601String(),
          lastDayOfCurrentMonth.toIso8601String()
        ],
        orderBy: 'id DESC',
      );
      return results.map((map) => Expense.fromMap(map)).toList();
    });
  }

  Future<List<Expense>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    var result = await db.query(
      'expenses',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Salaried Person operations
  Future<int> insertSalariedPerson(SalariedPerson person) async {
    final db = await database;
    return await db.insert('salaried_persons', person.toMap());
  }

  Future<List<SalariedPerson>> getAllSalariedPersons() async {
    final db = await database;
    var result = await db.query('salaried_persons');
    return result.map((p) => SalariedPerson.fromMap(p)).toList();
  }

  Future<int> updateSalariedPerson(SalariedPerson person) async {
    final db = await database;
    return await db.update(
      'salaried_persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deleteSalariedPerson(int id) async {
    final db = await database;
    return await db.delete(
      'salaried_persons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Income operations
  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('incomes', income.toMap());
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await database;
    var result = await db.query('incomes');
    return result.map((i) => Income.fromMap(i)).toList();
  }

  Future<List<Income>> getCurrentMonthIncome() async {
    final db = await database;
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 1);

    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [
        firstDayOfCurrentMonth.toIso8601String(),
        lastDayOfCurrentMonth.toIso8601String()
      ],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<List<Income>> getLast3MonthsIncomes() async {
    final db = await database;
    final now = DateTime.now();
    final firstDayOfEarliestMonth = DateTime(now.year, now.month - 2, 1);
    final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 1);

    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [
        firstDayOfEarliestMonth.toIso8601String(),
        lastDayOfCurrentMonth.toIso8601String()
      ],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<List<Income>> getIncomesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    var result = await db.query(
      'incomes',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    return result.map((i) => Income.fromMap(i)).toList();
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Summary and reporting methods
  Future<double> getTotalExpenses() async {
    final db = await database;
    var result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalIncomes() async {
    final db = await database;
    var result = await db.rawQuery('SELECT SUM(amount) as total FROM incomes');
    return result.first['total'] as double? ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getLast12MonthsFinancialSummary() async {
    final db = await database;
    final List<Map<String, dynamic>> monthlySummaries = [];

    final now = DateTime.now();
    final dateFormat = DateFormat('MMM yy');

    for (int i = 0; i < 12; i++) {
      // Calculate month boundaries (going back from current month)
      final monthDate = DateTime(now.year, now.month - i, 1);
      final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 1);

      // Format month name (e.g., "Jan 2023")
      final monthName = dateFormat.format(firstDayOfMonth);

      // Query total income for the month
      final incomeResult = await db.rawQuery('''
        SELECT SUM(amount) as total_income 
        FROM incomes 
        WHERE date_time >= ? AND date_time < ?
      ''', [firstDayOfMonth.toIso8601String(), lastDayOfMonth.toIso8601String()]);

      final totalIncome = incomeResult.first['total_income'] as double? ?? 0.0;

      // Query total expenses for the month
      final expenseResult = await db.rawQuery('''
        SELECT SUM(amount) as total_expense 
        FROM expenses 
        WHERE date_time >= ? AND date_time < ?
      ''', [firstDayOfMonth.toIso8601String(), lastDayOfMonth.toIso8601String()]);

      final totalExpense =
          expenseResult.first['total_expense'] as double? ?? 0.0;

      // Calculate savings
      if (totalIncome > 0 || totalExpense > 0) {
        final savings = totalIncome - totalExpense;

        monthlySummaries.add({
          'month': monthName,
          'total_income': totalIncome,
          'total_expense': totalExpense,
          'savings': savings,
        });
      }
    }

    // Reverse to show oldest first (optional - remove if you want newest first)
    return monthlySummaries;
  }
}
