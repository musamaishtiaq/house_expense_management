import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../widgets/dbHelper.dart';
import '../helper/colors.dart' as color;

class SubCategoryScreen extends StatefulWidget {
  final ExpenseCategory category;

  const SubCategoryScreen({super.key, required this.category});

  @override
  _SubCategoryScreenState createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  List<ExpenseSubCategory> _subCategories = [];
  final TextEditingController _titleController = TextEditingController();
  ExpenseSubCategory? _editingSubCategory;
  Map<int, double> _monthlyExpense = {};

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadSubCategories() async {
    final subCategories =
        await _dbHelper.getSubCategoriesForCategory(widget.category.id!);
    setState(() {
      _subCategories = subCategories;
    });
  }

  Future<void> _loadData() async {
    final expenses = await _dbHelper
        .getCurrentMonthExpensesBySubCategory(widget.category.id!);
    setState(() {
      _monthlyExpense = expenses;
    });
  }

  double _fetchSubCategoryExpense(int subCategoryId) {
    return (_monthlyExpense.containsKey(subCategoryId))
        ? _monthlyExpense[subCategoryId]!
        : 0;
  }

  void _showSubCategoryDialog({ExpenseSubCategory? subCategory}) {
    _editingSubCategory = subCategory;
    _titleController.text = subCategory?.title ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subCategory == null ? 'Add SubCategory' : 'Edit SubCategory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.AppColor.main1Color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'For: ${widget.category.title}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'SubCategory Name',
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

                      if (_editingSubCategory == null) {
                        await _dbHelper.insertExpenseSubCategory(
                          ExpenseSubCategory(
                            title: _titleController.text.trim(),
                            expenseCategoryId: widget.category.id!,
                          ),
                        );
                      } else {
                        await _dbHelper.updateExpenseSubCategory(
                          ExpenseSubCategory(
                            id: _editingSubCategory!.id,
                            title: _titleController.text.trim(),
                            expenseCategoryId: widget.category.id!,
                          ),
                        );
                      }

                      _titleController.clear();
                      Navigator.pop(context);
                      _loadSubCategories();
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

  Future<void> _deleteSubCategory(int id) async {
    await _dbHelper.deleteExpenseSubCategory(id);
    _loadSubCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title), // Show category title in app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (_subCategories.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No subcategories added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _subCategories.length,
                  itemBuilder: (context, index) {
                    final subCategory = _subCategories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[50],
                      child: ListTile(
                        title: Text(
                          subCategory.title,
                          style: TextStyle(color: color.AppColor.gray1Color),
                        ),
                        trailing: Text(
                          NumberFormat('#,##0').format(
                              _fetchSubCategoryExpense(subCategory.id!)),
                          style: TextStyle(
                            color: color.AppColor.main1Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onLongPress: () =>
                            _showSubCategoryDialog(subCategory: subCategory),
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
              child: const Text('Add SubCategory'),
              onPressed: () => _showSubCategoryDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
