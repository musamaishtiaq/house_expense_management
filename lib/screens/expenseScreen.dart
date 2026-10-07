import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../helper/colors.dart';
import '../widgets/appWidgets.dart';
import '../widgets/dbHelper.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  List<ExpenseCategory> _categories = [];
  List<ExpenseSubCategory> _subCategories = [];
  List<ExpenseSubCategory> _allSubCategories = [];
  Expense? _expense;
  bool _showAggregated = false;
  int? _expandedSubCategoryId;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  // For expense dialog
  ExpenseCategory? _selectedCategory;
  ExpenseSubCategory? _selectedSubCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month, now.day);
    _loadAllSubCategories();
    _loadCategories();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _loadData() async {
    final start = _dateOnly(_rangeStart);
    final endExclusive = _dateOnly(_rangeEnd).add(const Duration(days: 1));
    final expenses = await _dbHelper.getExpensesByDateRange(start, endExclusive);

    setState(() {
      _expenses = expenses;
      _applyFilter();
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getAllExpenseCategories();
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
        _loadSubCategories(categories.first.id!);
      }
    });
  }

  Future<void> _loadAllSubCategories() async {
    final subCats = await _dbHelper.getAllSubCategories();
    setState(() {
      _allSubCategories = subCats;
    });
  }

  Future<List<ExpenseSubCategory>> _fetchSubCategories(int categoryId) async {
    return _dbHelper.getSubCategoriesForCategory(categoryId);
  }

  Future<void> _loadSubCategories(int categoryId) async {
    final subCategories = await _fetchSubCategories(categoryId);
    if (!mounted) return;
    setState(() {
      _subCategories = subCategories;
      if (subCategories.isNotEmpty) {
        _selectedSubCategory = subCategories.first;
      } else {
        _selectedSubCategory = null;
      }
    });
  }

  void _applyFilter() {
    if (_showAggregated) {
      final Map<int, Expense> aggregates = {};
      for (final expense in _expenses) {
        final key = expense.expenseSubCategoryId;
        if (aggregates.containsKey(key)) {
          aggregates[key]!.amount += expense.amount;
        } else {
          aggregates[key] = Expense(
            id: expense.expenseSubCategoryId,
            expenseSubCategoryId: expense.expenseSubCategoryId,
            amount: expense.amount,
            dateTime: expense.dateTime,
            description: 'Range Total',
          );
        }
      }
      _filteredExpenses = aggregates.values.toList();
    } else {
      _filteredExpenses = List.from(_expenses);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColor.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      _rangeStart = _dateOnly(picked.start);
      _rangeEnd = _dateOnly(picked.end);
    });
    await _loadData();
  }

  void _toggleFilter() {
    setState(() {
      _showAggregated = !_showAggregated;
      _expandedSubCategoryId = null;
      _applyFilter();
    });
  }

  void _toggleSubCategoryExpand(int subCategoryId) {
    setState(() {
      _expandedSubCategoryId =
          _expandedSubCategoryId == subCategoryId ? null : subCategoryId;
    });
  }

  Future<void> _showExpenseDialog({Expense? expense}) async {
    _expense = expense;

    final categories = await _dbHelper.getAllExpenseCategories();
    final allSubs = await _dbHelper.getAllSubCategories();
    if (!mounted) return;

    _categories = categories;
    _allSubCategories = allSubs;

    _selectedDate = _expense?.dateTime ?? DateTime.now();
    _dateController.text =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    if (_expense != null) {
      _amountController.text = _expense?.amount.toStringAsFixed(0) ?? '';
      _descriptionController.text = _expense?.description ?? '';
      final subCat = allSubs.firstWhere(
        (sc) => sc.id == expense?.expenseSubCategoryId,
        orElse: () => allSubs.isNotEmpty
            ? allSubs.first
            : ExpenseSubCategory(title: '', expenseCategoryId: 0),
      );
      final cat = categories.firstWhere(
        (c) => c.id == subCat.expenseCategoryId,
        orElse: () => categories.first,
      );
      _subCategories = await _fetchSubCategories(cat.id!);
      _selectedCategory = cat;
      _selectedSubCategory = _subCategories.firstWhere(
        (sc) => sc.id == subCat.id,
        orElse: () =>
            _subCategories.isNotEmpty ? _subCategories.first : subCat,
      );
    } else {
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = categories.isNotEmpty ? categories.first : null;
      if (_selectedCategory != null) {
        _subCategories =
            await _fetchSubCategories(_selectedCategory!.id!);
        _selectedSubCategory =
            _subCategories.isNotEmpty ? _subCategories.first : null;
      } else {
        _subCategories = [];
        _selectedSubCategory = null;
      }
    }
    if (!mounted) return;
    setState(() {});

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> selectDate() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColor.primary, // Header color
                        onPrimary: Colors.white, // Header text color
                        onSurface: Colors.black, // Calendar text color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColor.primary, // Button color
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                  _dateController.text =
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
                });
              }
            }

            return Dialog(
              backgroundColor: AppColor.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense == null ? 'Add Expense' : 'Edit Expense',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _selectedCategory,
                      decoration: appInputDecoration(label: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<ExpenseCategory>(
                          value: category,
                          child: Text(category.title),
                        );
                      }).toList(),
                      onChanged: (category) async {
                        if (category == null) return;
                        final subCategories =
                            await _fetchSubCategories(category.id!);
                        setState(() {
                          _selectedCategory = category;
                          _subCategories = subCategories;
                          _selectedSubCategory = subCategories.isNotEmpty
                              ? subCategories.first
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subcategory Dropdown
                    DropdownButtonFormField<ExpenseSubCategory>(
                      value: _selectedSubCategory,
                      decoration: appInputDecoration(label: 'Subcategory'),
                      items: _subCategories.map((subCategory) {
                        return DropdownMenuItem<ExpenseSubCategory>(
                          value: subCategory,
                          child: Text(subCategory.title),
                        );
                      }).toList(),
                      onChanged: (subCategory) {
                        setState(() {
                          _selectedSubCategory = subCategory;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextField(
                      controller: _amountController,
                      decoration: appInputDecoration(
                        label: 'Amount',
                        prefixText: 'Rs ',
                      ),
                      cursorColor: AppColor.textPrimary,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: appInputDecoration(
                        label: 'Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: AppColor.primary),
                          onPressed: selectDate,
                        ),
                      ),
                      onTap: selectDate,
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      decoration: appInputDecoration(
                        label: 'Description (Optional)',
                      ),
                      cursorColor: AppColor.textPrimary,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (_selectedSubCategory == null ||
                                _amountController.text.isEmpty) return;

                            final amount =
                                double.tryParse(_amountController.text) ?? 0;

                            if (_expense == null) {
                              await _dbHelper.insertExpense(
                                Expense(
                                  expenseSubCategoryId:
                                      _selectedSubCategory!.id!,
                                  amount: amount,
                                  dateTime: _selectedDate,
                                  description:
                                      _descriptionController.text.trim(),
                                ),
                              );
                            } else {
                              await _dbHelper.updateExpense(
                                Expense(
                                  id: expense?.id,
                                  expenseSubCategoryId:
                                      _selectedSubCategory!.id!,
                                  amount: amount,
                                  dateTime: _selectedDate,
                                  description:
                                      _descriptionController.text.trim(),
                                ),
                              );
                            }

                            _amountController.clear();
                            _descriptionController.clear();
                            Navigator.pop(context);
                            _loadData();
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: const Text('Expense Records'),
        actions: [
          IconButton(
            icon: Icon(
                _showAggregated ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: _toggleFilter,
            tooltip: _showAggregated
                ? 'Show All Entries'
                : 'Show Subcategory Totals',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildRangeDateField(onTap: _pickDateRange),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _buildExpenseList(),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Add Expense',
                    onPressed: () => _showExpenseDialog(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_filteredExpenses.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No expense records yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _filteredExpenses.length,
        itemBuilder: (context, index) {
          final expense = _filteredExpenses[index];
          final subCategory = _allSubCategories.firstWhere(
            (sc) => sc.id == expense.expenseSubCategoryId,
            orElse: () => ExpenseSubCategory(
              id: -1,
              title: 'Unknown',
              expenseCategoryId: -1,
            ),
          );
          final category = _categories.firstWhere(
            (c) => c.id == subCategory.expenseCategoryId,
            orElse: () => ExpenseCategory(
              id: -1,
              title: 'Unknown',
            ),
          );

          if (_showAggregated) {
            return _buildAggregatedExpenseCard(
                expense, subCategory, category);
          }

          return AppCard(
            onLongPress: () => _showExpenseDialog(expense: expense),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subCategory.title,
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${expense.dateTime.day}/${expense.dateTime.month}/${expense.dateTime.year}',
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat('#,##0').format(expense.amount),
                  style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRangeDateField({required VoidCallback onTap}) {
    final startLabel =
        '${_rangeStart.day}/${_rangeStart.month}/${_rangeStart.year}';
    final endLabel = '${_rangeEnd.day}/${_rangeEnd.month}/${_rangeEnd.year}';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: AppColor.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date range',
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 11),
                ),
                Text(
                  '$startLabel – $endLabel',
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_today,
              size: 18, color: AppColor.textSecondary),
        ],
      ),
    );
  }

  Widget _buildAggregatedExpenseCard(
    Expense expense,
    ExpenseSubCategory subCategory,
    ExpenseCategory category,
  ) {
    final isExpanded = _expandedSubCategoryId == expense.expenseSubCategoryId;
    final entries = _entriesForSubCategory(expense.expenseSubCategoryId);
    final overBudget =
        subCategory.budget > 0 && expense.amount > subCategory.budget;

    return AppCard(
      onTap: () => _toggleSubCategoryExpand(expense.expenseSubCategoryId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subCategory.title,
                      style: const TextStyle(
                        color: AppColor.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${category.title} · ${entries.length} entries',
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat('#,##0').format(expense.amount),
                    style: TextStyle(
                      color: overBudget ? AppColor.expense : AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subCategory.budget > 0)
                    Text(
                      'Budget ${NumberFormat('#,##0').format(subCategory.budget)}',
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColor.textSecondary,
              ),
            ],
          ),
          AppBudgetBar(actual: expense.amount, budget: subCategory.budget),
          if (isExpanded)
            ...entries.map((entry) {
              return InkWell(
                onLongPress: () => _showExpenseDialog(expense: entry),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year}',
                          style: const TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        NumberFormat('#,##0').format(entry.amount),
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  List<Expense> _entriesForSubCategory(int subCategoryId) {
    return _expenses
        .where((e) => e.expenseSubCategoryId == subCategoryId)
        .toList();
  }
}
