import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../widgets/dbHelper.dart';
import '../helper/colors.dart' as color;

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
  final DateTime _currentDate = DateTime.now();

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

  Future<void> _loadData() async {
    final expenses = await _dbHelper.getLast3MonthsExpenses();

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

  Future<void> _loadSubCategories(int categoryId) async {
    final subCategories = _allSubCategories
        .where((sc) => sc.expenseCategoryId == categoryId)
        .toList();
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
      // Create monthly aggregates
      final Map<String, Expense> monthlyAggregates = {};

      for (final expense in _expenses) {
        if (expense.dateTime.year == _currentDate.year &&
            expense.dateTime.month == _currentDate.month) {
          final key = '${expense.expenseSubCategoryId}';
          if (monthlyAggregates.containsKey(key)) {
            monthlyAggregates[key]!.amount += expense.amount;
          } else {
            monthlyAggregates[key] = Expense(
              id: expense
                  .expenseSubCategoryId, // Using subcategory ID as temporary ID
              expenseSubCategoryId: expense.expenseSubCategoryId,
              amount: expense.amount,
              dateTime: DateTime(_currentDate.year, _currentDate.month),
              description: 'Monthly Total',
            );
          }
        }
      }

      _filteredExpenses = monthlyAggregates.values.toList();
    } else {
      _filteredExpenses = List.from(_expenses);
    }
  }

  void _toggleFilter() {
    setState(() {
      _showAggregated = !_showAggregated;
      _applyFilter();
    });
  }

  void _showExpenseDialog({Expense? expense}) {
    _expense = expense;

    _selectedDate = _expense?.dateTime ?? DateTime.now();
    _dateController.text =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    if (_expense != null) {
      _amountController.text = _expense?.amount.toStringAsFixed(0) ?? '';
      _descriptionController.text = _expense?.description ?? '';
      final subCat = _allSubCategories.firstWhere(
        (sc) => sc.id == expense?.expenseSubCategoryId,
        orElse: () => _subCategories.first,
      );
      final cat = _categories.firstWhere(
        (c) => c.id == subCat.expenseCategoryId,
        orElse: () => _categories.first,
      );
      _loadSubCategories(cat.id!);

      _selectedCategory = cat;
      _selectedSubCategory = subCat;
    } else {
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      _loadSubCategories(_categories.first.id!);

      _selectedSubCategory =
          _subCategories.isNotEmpty ? _subCategories.first : null;
    }
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
                        primary: color.AppColor.main1Color, // Header color
                        onPrimary: Colors.white, // Header text color
                        onSurface: Colors.black, // Calendar text color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              color.AppColor.main1Color, // Button color
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
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                        color: color.AppColor.main1Color,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<ExpenseCategory>(
                          value: category,
                          child: Text(category.title),
                        );
                      }).toList(),
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                          _selectedSubCategory = null;
                          _loadSubCategories(category!.id!);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subcategory Dropdown
                    DropdownButtonFormField<ExpenseSubCategory>(
                      value: _selectedSubCategory,
                      decoration: InputDecoration(
                        labelText: 'Subcategory',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
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
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: 'Rs ',
                      ),
                      cursorColor: color.AppColor.blackColor,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today,
                              color: color.AppColor.main1Color),
                          onPressed: selectDate,
                        ),
                      ),
                      onTap: selectDate,
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      cursorColor: color.AppColor.blackColor,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.AppColor.main1Color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
      appBar: AppBar(
        title: const Text('Expense Records'),
        actions: [
          IconButton(
            icon: Icon(
                _showAggregated ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: _toggleFilter,
            tooltip: _showAggregated
                ? 'Show All Entries'
                : 'Show Monthly Aggregates',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            height: 32,
            width: MediaQuery.of(context).size.width,
            color: color.AppColor.gray1Color,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Last 3 Months',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildExpenseList(),
                  const SizedBox(
                    height: 12,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.AppColor.main1Color,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Add Expense'),
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

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.grey[50],
            child: ListTile(
              title: Text(subCategory.title),
              subtitle: Text(
                _showAggregated
                    ? '${expense.dateTime.month}/${expense.dateTime.year}'
                    : '${expense.dateTime.day}/${expense.dateTime.month}/${expense.dateTime.year}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat('#,##0').format(expense.amount),
                    style: TextStyle(
                      color: color.AppColor.main1Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_showAggregated)
                    Text(
                      '${_getEntryCount(expense.expenseSubCategoryId)} entries',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              onLongPress: () =>
                  _showAggregated ? {} : _showExpenseDialog(expense: expense),
            ),
          );
        },
      ),
    );
  }

  int _getEntryCount(int subCategoryId) {
    return _expenses
        .where((e) =>
            e.expenseSubCategoryId == subCategoryId &&
            e.dateTime.year == _currentDate.year &&
            e.dateTime.month == _currentDate.month)
        .length;
  }
}
