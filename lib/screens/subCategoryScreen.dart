import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../helper/colors.dart';
import '../widgets/appWidgets.dart';
import '../widgets/dbHelper.dart';

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
  final TextEditingController _budgetController = TextEditingController();
  ExpenseSubCategory? _editingSubCategory;
  Map<int, double> _monthlyExpense = {};
  bool _reorderMode = false;

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
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
    _budgetController.text = (subCategory == null || subCategory.budget == 0)
        ? ''
        : subCategory.budget.toStringAsFixed(
            subCategory.budget.truncateToDouble() == subCategory.budget
                ? 0
                : 2,
          );

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
                subCategory == null ? 'Add SubCategory' : 'Edit SubCategory',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'For: ${widget.category.title}',
                style: const TextStyle(
                  color: AppColor.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: appInputDecoration(label: 'SubCategory Name'),
                cursorColor: AppColor.textPrimary,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                decoration: appInputDecoration(
                  label: 'Monthly Budget (Optional)',
                  prefixText: 'Rs ',
                ),
                cursorColor: AppColor.textPrimary,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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

                      final budget =
                          double.tryParse(_budgetController.text.trim()) ?? 0;

                      if (_editingSubCategory == null) {
                        await _dbHelper.insertExpenseSubCategory(
                          ExpenseSubCategory(
                            title: _titleController.text.trim(),
                            expenseCategoryId: widget.category.id!,
                            budget: budget,
                          ),
                        );
                      } else {
                        await _dbHelper.updateExpenseSubCategory(
                          ExpenseSubCategory(
                            id: _editingSubCategory!.id,
                            title: _titleController.text.trim(),
                            expenseCategoryId: widget.category.id!,
                            budget: budget,
                          ),
                        );
                      }

                      _titleController.clear();
                      _budgetController.clear();
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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final subCategory = _subCategories.removeAt(oldIndex);
      _subCategories.insert(newIndex, subCategory);
    });
    await _dbHelper.updateExpenseSubCategoriesOrder(_subCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: Text(widget.category.title),
        actions: [
          IconButton(
            tooltip: _reorderMode ? 'Done rearranging' : 'Rearrange items',
            icon: Icon(_reorderMode ? Icons.done : Icons.reorder),
            onPressed: () {
              setState(() => _reorderMode = !_reorderMode);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _subCategories.length,
                  onReorder: _reorderMode ? _onReorder : (_, __) {},
                  itemBuilder: (context, index) {
                    final subCategory = _subCategories[index];
                    final actual =
                        _fetchSubCategoryExpense(subCategory.id!);
                    final overBudget = subCategory.budget > 0 &&
                        actual > subCategory.budget;
                    return AppCard(
                      key: ValueKey(subCategory.id),
                      onLongPress: _reorderMode
                          ? null
                          : () =>
                              _showSubCategoryDialog(subCategory: subCategory),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (_reorderMode) ...[
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(
                                    Icons.drag_handle,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  subCategory.title,
                                  style: const TextStyle(
                                    color: AppColor.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    NumberFormat('#,##0').format(actual),
                                    style: TextStyle(
                                      color: overBudget
                                          ? AppColor.expense
                                          : AppColor.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (subCategory.budget > 0)
                                    Text(
                                      'Budget ${NumberFormat('#,##0').format(subCategory.budget)}',
                                      style: const TextStyle(
                                        color: AppColor.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          AppBudgetBar(
                            actual: actual,
                            budget: subCategory.budget,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Add SubCategory',
              onPressed: () => _showSubCategoryDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
