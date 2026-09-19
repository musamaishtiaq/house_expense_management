import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helper/colors.dart' as color;
import '../models/appSettings.dart';
import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../widgets/dbHelper.dart';

class ExpenseInsightScreen extends StatefulWidget {
  const ExpenseInsightScreen({super.key});

  @override
  _ExpenseInsightScreenState createState() => _ExpenseInsightScreenState();
}

class _ExpenseInsightScreenState extends State<ExpenseInsightScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();

  static const List<int> _hintMonthOptions = [3, 6, 9, 12];

  AppSettings _settings = AppSettings();
  List<ExpenseCategory> _categories = [];
  List<ExpenseSubCategory> _subCategories = [];
  Map<int, double> _basicByCategory = {};
  Map<int, double> _basicBySubCategory = {};
  Map<int, double> _actualByCategory = {};
  Map<int, double> _actualBySubCategory = {};
  final Set<int> _expandedCategoryIds = {};
  double _totalBasicNeed = 0;
  double _totalActual = 0;
  double _currentMonthIncome = 0;
  double _currentMonthSavings = 0;
  bool _loading = true;
  bool _showAmount = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final settings = await _dbHelper.getAppSettings();
    final months = _hintMonthOptions.contains(settings.hintMonths)
        ? settings.hintMonths
        : 3;

    final categories = await _dbHelper.getAllExpenseCategories();
    final subCategories = await _dbHelper.getAllSubCategories();
    final basicByCategory =
        await _dbHelper.getAverageMonthlyExpensesByCategory(months);
    final basicBySubCategory =
        await _dbHelper.getAverageMonthlyExpensesBySubCategory(months);
    final actualByCategory =
        await _dbHelper.getCurrentMonthExpensesByCategory();
    final actualBySubCategory =
        await _dbHelper.getCurrentMonthExpensesByAllSubCategories();
    final totalActual = await _dbHelper.getCurrentMonthTotalExpenses();
    final currentMonthIncome = await _dbHelper.getCurrentMonthTotalIncome();

    double totalBasic = 0;
    for (final value in basicByCategory.values) {
      totalBasic += value;
    }

    if (!mounted) return;
    setState(() {
      _settings = AppSettings(
        id: settings.id,
        hintMonths: months,
        monthlySavingsTarget: settings.monthlySavingsTarget,
      );
      _categories = categories;
      _subCategories = subCategories;
      _basicByCategory = basicByCategory;
      _basicBySubCategory = basicBySubCategory;
      _actualByCategory = actualByCategory;
      _actualBySubCategory = actualBySubCategory;
      _totalBasicNeed = totalBasic;
      _totalActual = totalActual;
      _currentMonthIncome = currentMonthIncome;
      _currentMonthSavings = currentMonthIncome - totalActual;
      _loading = false;
    });
  }

  Future<void> _onHintMonthsChanged(int? months) async {
    if (months == null || months == _settings.hintMonths) return;

    final updated = AppSettings(
      id: _settings.id,
      hintMonths: months,
      monthlySavingsTarget: _settings.monthlySavingsTarget,
    );
    await _dbHelper.updateAppSettings(updated);
    await _loadData();
  }

  double _valueFor(int? id, Map<int, double> map) =>
      id != null && map.containsKey(id) ? map[id]! : 0;

  String _fmt(double value) =>
      _showAmount ? NumberFormat('#,##0').format(value) : '****';

  void _toggleAmount() {
    setState(() => _showAmount = !_showAmount);
  }

  Widget _sectionBar(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 32,
      width: MediaQuery.of(context).size.width,
      color: color.AppColor.gray1Color,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'OpenSans',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color.AppColor.blackColor,
      ),
    );
  }

  Widget _summaryBox(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.AppColor.gray2Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _amountRow(String label, double value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: color.AppColor.gray1Color,
            ),
          ),
          InkWell(
            onDoubleTap: _toggleAmount,
            child: Text(
              _fmt(value),
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? color.AppColor.main1Color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final difference = _totalActual - _totalBasicNeed;
    final overBasic = difference > 0;
    final savingsTarget = _settings.monthlySavingsTarget;
    final savingsGap = savingsTarget - _currentMonthSavings;
    final onTrack = _currentMonthSavings >= savingsTarget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Insight'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _sectionBar('Hint Months'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Basic need from last',
                          style: TextStyle(color: color.AppColor.gray1Color),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _settings.hintMonths,
                        underline: Container(
                          height: 1,
                          color: color.AppColor.main1Color,
                        ),
                        items: _hintMonthOptions
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('$m months'),
                                ))
                            .toList(),
                        onChanged: _onHintMonthsChanged,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        children: [
                          _sectionTitle('This Month Summary'),
                          const SizedBox(height: 8),
                          _summaryBox([
                            _amountRow('Total basic need', _totalBasicNeed),
                            _amountRow('Total actual expense', _totalActual),
                            const Divider(),
                            _amountRow(
                              overBasic ? 'Over basic need' : 'Under basic need',
                              difference.abs(),
                              valueColor: overBasic
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                          ]),
                          const SizedBox(height: 16),
                          _sectionTitle('Savings Target'),
                          const SizedBox(height: 8),
                          _summaryBox([
                            _amountRow('Target', savingsTarget),
                            _amountRow(
                                'Income (this month)', _currentMonthIncome),
                            _amountRow('Actual savings', _currentMonthSavings),
                            const Divider(),
                            if (savingsTarget <= 0)
                              Text(
                                'Set a savings target in Settings',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              )
                            else
                              _amountRow(
                                onTrack ? 'On track' : 'Need to save more',
                                onTrack ? 0 : savingsGap,
                                valueColor: onTrack
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                          ]),
                          const SizedBox(height: 16),
                          _sectionTitle('Categories'),
                          const SizedBox(height: 8),
                          if (_categories.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No categories added yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            ..._buildCategoryCards(),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _loadData,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Refresh Records',
                                  style: TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 14,
                                    color: color.AppColor.blackColor,
                                  ),
                                ),
                              ],
                            ),
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

  List<Widget> _buildCategoryCards() {
    final widgets = <Widget>[];
    for (final category in _categories) {
      final basic = _valueFor(category.id, _basicByCategory);
      final actual = _valueFor(category.id, _actualByCategory);
      final exceeded = actual > basic && (actual > 0 || basic > 0);
      final isExpanded = _expandedCategoryIds.contains(category.id);
      final subs = _subCategories
          .where((s) => s.expenseCategoryId == category.id)
          .toList();

      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.grey[50],
          child: ListTile(
            title: Text(
              category.title,
              style: TextStyle(color: color.AppColor.gray1Color),
            ),
            subtitle: Text(
              exceeded ? 'Over basic need' : 'Basic ${_fmt(basic)}',
              style: TextStyle(
                fontSize: 12,
                color: exceeded ? Colors.red[700] : Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onDoubleTap: _toggleAmount,
                  child: Text(
                    _fmt(actual),
                    style: TextStyle(
                      color: color.AppColor.main1Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: color.AppColor.gray1Color,
                ),
              ],
            ),
            onTap: () {
              if (category.id == null) return;
              setState(() {
                if (isExpanded) {
                  _expandedCategoryIds.remove(category.id);
                } else {
                  _expandedCategoryIds.add(category.id!);
                }
              });
            },
          ),
        ),
      );

      if (isExpanded) {
        if (subs.isEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                'No subcategories',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          );
        } else {
          for (final sub in subs) {
            final subBasic = _valueFor(sub.id, _basicBySubCategory);
            final subActual = _valueFor(sub.id, _actualBySubCategory);
            final subExceeded =
                subActual > subBasic && (subActual > 0 || subBasic > 0);

            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.grey[50],
                  child: ListTile(
                    dense: true,
                    title: Text(
                      sub.title,
                      style: TextStyle(color: color.AppColor.gray1Color),
                    ),
                    subtitle: Text(
                      subExceeded
                          ? 'Over basic need'
                          : 'Basic ${_fmt(subBasic)}',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            subExceeded ? Colors.red[700] : Colors.grey[600],
                      ),
                    ),
                    trailing: InkWell(
                      onDoubleTap: _toggleAmount,
                      child: Text(
                        _fmt(subActual),
                        style: TextStyle(
                          color: color.AppColor.main1Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }
    }
    return widgets;
  }
}
