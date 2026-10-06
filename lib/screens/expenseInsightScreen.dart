import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helper/colors.dart';
import '../models/appSettings.dart';
import '../models/expenseCategory.dart';
import '../models/expenseSubCategory.dart';
import '../widgets/appWidgets.dart';
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
  int? _expandedCategoryId;
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

  @override
  Widget build(BuildContext context) {
    final difference = _totalActual - _totalBasicNeed;
    final overBasic = difference > 0;
    final savingsTarget = _settings.monthlySavingsTarget;
    final savingsGap = savingsTarget - _currentMonthSavings;
    final onTrack = _currentMonthSavings >= savingsTarget;

    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: const Text('Expense Insight'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const AppSectionLabel('Hint Months'),
                  AppCard(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Basic need from last',
                            style: TextStyle(color: AppColor.textSecondary),
                          ),
                        ),
                        DropdownButton<int>(
                          value: _settings.hintMonths,
                          underline: Container(
                            height: 1,
                            color: AppColor.primary,
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
                  const AppSectionLabel('This Month Summary'),
                  if (_totalActual > 0) ...[
                    AppCard(
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(180, 180),
                              painter: _DonutPainter(
                                values: _categories
                                    .map((c) =>
                                        _valueFor(c.id, _actualByCategory))
                                    .toList(),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Total actual expense',
                                  style: TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                InkWell(
                                  onDoubleTap: _toggleAmount,
                                  child: Text(
                                    _fmt(_totalActual),
                                    style: const TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  AppCard(
                    child: Column(
                      children: [
                        _amountRow('Total basic need', _totalBasicNeed),
                        _amountRow('Total actual expense', _totalActual),
                        const Divider(color: AppColor.divider),
                        _amountRow(
                          overBasic ? 'Over basic need' : 'Under basic need',
                          difference.abs(),
                          valueColor: overBasic
                              ? AppColor.expense
                              : AppColor.income,
                        ),
                      ],
                    ),
                  ),
                  const AppSectionLabel('Savings Target'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _amountRow('Target', savingsTarget),
                        _amountRow(
                            'Income (this month)', _currentMonthIncome),
                        _amountRow('Actual savings', _currentMonthSavings),
                        const Divider(color: AppColor.divider),
                        if (savingsTarget <= 0)
                          const Text(
                            'Set a savings target in Settings',
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 13,
                              color: AppColor.textSecondary,
                            ),
                          )
                        else
                          _amountRow(
                            onTrack ? 'On track' : 'Need to save more',
                            onTrack ? 0 : savingsGap,
                            valueColor: onTrack
                                ? AppColor.income
                                : AppColor.expense,
                          ),
                      ],
                    ),
                  ),
                  const AppSectionLabel('Categories'),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 20, color: AppColor.primary),
                        SizedBox(width: 8),
                        Text(
                          'Refresh Records',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 14,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _amountRow(String label, double value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: AppColor.textSecondary,
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
                color: valueColor ?? AppColor.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double actual, double basic, bool exceeded) {
    final max = math.max(basic, actual);
    final value = max <= 0 ? 0.0 : (actual / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: AppColor.chipFill,
        color: exceeded ? AppColor.expense : AppColor.primary,
      ),
    );
  }

  List<Widget> _buildCategoryCards() {
    final widgets = <Widget>[];
    for (var i = 0; i < _categories.length; i++) {
      final category = _categories[i];
      final basic = _valueFor(category.id, _basicByCategory);
      final actual = _valueFor(category.id, _actualByCategory);
      final exceeded = actual > basic && (actual > 0 || basic > 0);
      final isExpanded = _expandedCategoryId == category.id;
      final subs = _subCategories
          .where((s) => s.expenseCategoryId == category.id)
          .toList();
      final chartColor =
          AppColor.chartColors[i % AppColor.chartColors.length];

      widgets.add(
        AppCard(
          onTap: () {
            if (category.id == null) return;
            setState(() {
              _expandedCategoryId =
                  isExpanded ? null : category.id;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: chartColor.withValues(alpha: 0.15),
                    child: Icon(Icons.circle, size: 12, color: chartColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: const TextStyle(
                            color: AppColor.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          exceeded ? 'Over basic need' : 'Basic ${_fmt(basic)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: exceeded
                                ? AppColor.expense
                                : AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onDoubleTap: _toggleAmount,
                    child: AppAmountText(
                      text: _fmt(actual),
                      color: exceeded ? AppColor.expense : AppColor.primary,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColor.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _progressBar(actual, basic, exceeded),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                if (subs.isEmpty)
                  const Text(
                    'No subcategories',
                    style: TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 13,
                    ),
                  )
                else
                  ...subs.map((sub) {
                    final subBasic = _valueFor(sub.id, _basicBySubCategory);
                    final subActual =
                        _valueFor(sub.id, _actualBySubCategory);
                    final subExceeded = subActual > subBasic &&
                        (subActual > 0 || subBasic > 0);
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.title,
                                      style: const TextStyle(
                                        color: AppColor.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      subExceeded
                                          ? 'Over basic need'
                                          : 'Basic ${_fmt(subBasic)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subExceeded
                                            ? AppColor.expense
                                            : AppColor.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onDoubleTap: _toggleAmount,
                                child: Text(
                                  _fmt(subActual),
                                  style: TextStyle(
                                    color: subExceeded
                                        ? AppColor.expense
                                        : AppColor.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _progressBar(subActual, subBasic, subExceeded),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;

  _DonutPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi;
      stroke.color = AppColor.chartColors[i % AppColor.chartColors.length];
      canvas.drawArc(rect.deflate(12), start, sweep - 0.04, false, stroke);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}
