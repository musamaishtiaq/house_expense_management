import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/subCategoryScreen.dart';
import '../models/expenseCategory.dart';
import '../widgets/dbHelper.dart';
import '../helper/colors.dart' as color;

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
    setState(() {
      _categories = categories;
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

  void _showCategoryDialog({ExpenseCategory? category}) {
    _editingCategory = category;
    _titleController.text = category?.title ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[100], // Light gray background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
                  color: color.AppColor.main1Color,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.AppColor.main1Color),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                cursorColor: color.AppColor.blackColor,
                autofocus: true,
              ),
              const SizedBox(height: 24),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
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
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[50],
                      child: ListTile(
                        title: Text(
                          category.title,
                          style: TextStyle(color: color.AppColor.gray1Color),
                        ),
                        trailing: InkWell(
                          child: Text(
                            _showAmount ? NumberFormat('#,##0').format(_fetchCategoryExpense(category.id!)) : "****",
                            style: TextStyle(
                              color: color.AppColor.main1Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onDoubleTap: () {
                            setState(() {
                              _showAmount = !_showAmount;
                            });
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SubCategoryScreen(category: category),
                            ),
                          );
                        },
                        onLongPress: () =>
                            _showCategoryDialog(category: category),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(
              height: 12,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.AppColor.main1Color,
                foregroundColor: color.AppColor.whiteColor,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Add Category'),
              onPressed: () => _showCategoryDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
