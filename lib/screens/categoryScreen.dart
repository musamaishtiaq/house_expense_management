import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/subCategoryScreen.dart';
import '../models/expenseCategory.dart';
import '../helper/colors.dart';
import '../widgets/appWidgets.dart';
import '../widgets/dbHelper.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  List<ExpenseCategory> _categories = [];
  final TextEditingController _titleController = TextEditingController();
  ExpenseCategory? _editingCategory;
  bool _showAmount = false;
  Map<int, double> _monthlyExpense = {};
  Map<int, double> _categoryBudgets = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _dbHelper.getAllExpenseCategories();
    final subCategories = await _dbHelper.getAllSubCategories();
    final Map<int, double> budgets = {};
    for (final sub in subCategories) {
      budgets[sub.expenseCategoryId] =
          (budgets[sub.expenseCategoryId] ?? 0) + sub.budget;
    }
    setState(() {
      _categories = categories;
      _categoryBudgets = budgets;
    });
  }

  Future<void> _loadData() async {
    final expenses = await _dbHelper.getCurrentMonthExpensesByCategory();    
    setState(() {
      _monthlyExpense = expenses;
    });
  }

  double _fetchCategoryExpense(int categoryId) {
    return (_monthlyExpense.containsKey(categoryId))
        ? _monthlyExpense[categoryId]!
        : 0;
  }

  double _fetchCategoryBudget(int categoryId) {
    return _categoryBudgets[categoryId] ?? 0;
  }

  void _showCategoryDialog({ExpenseCategory? category}) {
    _editingCategory = category;
    _titleController.text = category?.title ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColor.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category == null ? 'Add Category' : 'Edit Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: appInputDecoration(label: 'Category Name'),
                cursorColor: AppColor.textPrimary,
                autofocus: true,
              ),
              const SizedBox(height: 24),
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
                      if (_titleController.text.trim().isEmpty) return;

                      if (_editingCategory == null) {
                        await _dbHelper.insertExpenseCategory(
                          ExpenseCategory(title: _titleController.text.trim()),
                        );
                      } else {
                        await _dbHelper.updateExpenseCategory(
                          ExpenseCategory(
                            id: _editingCategory!.id,
                            title: _titleController.text.trim(),
                          ),
                        );
                      }

                      _titleController.clear();
                      Navigator.pop(context);
                      _loadCategories();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    await _dbHelper.deleteExpenseCategory(id);
    _loadCategories();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);
    });
    await _dbHelper.updateExpenseCategoriesOrder(_categories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: const Text('Expense Categories'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            if (_categories.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No categories added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _categories.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final actual = _fetchCategoryExpense(category.id!);
                    final budget = _fetchCategoryBudget(category.id!);
                    final overBudget = budget > 0 && actual > budget;
                    return AppCard(
                      key: ValueKey(category.id),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SubCategoryScreen(category: category),
                          ),
                        );
                        _loadCategories();
                        _loadData();
                      },
                      onLongPress: () =>
                          _showCategoryDialog(category: category),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(
                                  Icons.drag_handle,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.title,
                                  style: const TextStyle(
                                    color: AppColor.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              InkWell(
                                onDoubleTap: () {
                                  setState(() {
                                    _showAmount = !_showAmount;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _showAmount
                                          ? NumberFormat('#,##0').format(actual)
                                          : '****',
                                      style: TextStyle(
                                        color: overBudget
                                            ? AppColor.expense
                                            : AppColor.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (budget > 0)
                                      Text(
                                        _showAmount
                                            ? 'Budget ${NumberFormat('#,##0').format(budget)}'
                                            : 'Budget ****',
                                        style: const TextStyle(
                                          color: AppColor.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          AppBudgetBar(actual: actual, budget: budget),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Add Category',
              onPressed: () => _showCategoryDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
