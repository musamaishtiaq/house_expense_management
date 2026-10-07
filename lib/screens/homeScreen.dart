import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../helper/colors.dart';
import '../helper/strings.dart' as string;
import '../screens/expenseScreen.dart';
import '../screens/incomeScreen.dart';
import '../widgets/appWidgets.dart';
import '../widgets/dbHelper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  double _savings = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;
  bool _showAmount = false;
  List<Map<String, dynamic>> _monthlySummaries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final incomes = await _dbHelper.getTotalIncomes();
    final expenses = await _dbHelper.getTotalExpenses();
    final monthIncome = await _dbHelper.getCurrentMonthTotalIncome();
    final monthExpense = await _dbHelper.getCurrentMonthTotalExpenses();
    final monthlySummaries = await _dbHelper.getLast12MonthsFinancialSummary();
    setState(() {
      _savings = incomes - expenses;
      _monthIncome = monthIncome;
      _monthExpense = monthExpense;
      _monthlySummaries = monthlySummaries;
    });
  }

  String _amount(num value) {
    return _showAmount ? NumberFormat('#,##0').format(value) : '****';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColor.headerStart, AppColor.headerEnd],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Text(
                  string.AppStrings.appName,
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Last 12 Months',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Total Savings',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onDoubleTap: () {
                    setState(() => _showAmount = !_showAmount);
                  },
                  child: Text(
                    _amount(_savings),
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _moneyActionCard(
                    label: 'Income',
                    value: _amount(_monthIncome),
                    icon: Icons.attach_money,
                    valueColor: AppColor.income,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IncomeScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _moneyActionCard(
                    label: 'Expense',
                    value: _amount(_monthExpense),
                    icon: Icons.money_off,
                    valueColor: AppColor.expense,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpenseScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Expanded(child: AppSectionLabel('Financial Summary')),
                IconButton(
                  tooltip: 'Refresh Records',
                  onPressed: _loadData,
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColor.headerEnd,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                _headerCell('Month', 2, Alignment.centerLeft),
                _headerCell('Income', 3, Alignment.centerRight),
                _headerCell('Expense', 3, Alignment.centerRight),
                _headerCell('Savings', 3, Alignment.centerRight),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _monthlySummaries.length,
              itemBuilder: (context, index) {
                final month = _monthlySummaries[index];
                final savings = month['savings'] as double;
                final isPositive = savings >= 0;
                return AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          month['month'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _amount(month['total_income'] as num),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColor.income,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _amount(month['total_expense'] as num),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColor.expense,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _amount(savings),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isPositive
                                  ? AppColor.income
                                  : AppColor.expense,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, int flex, Alignment alignment) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColor.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _moneyActionCard({
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColor.chipFill,
                child: Icon(icon, color: valueColor),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColor.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
