import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/expenseScreen.dart';
import '../screens/incomeScreen.dart';
import '../screens/categoryScreen.dart';
import '../screens/personScreen.dart';
import '../helper/colors.dart' as color;
import '../helper/strings.dart' as string;
import '../widgets/dbHelper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  double _savings = 0;
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
    final monthlySummaries = await _dbHelper.getLast12MonthsFinancialSummary();
    setState(() {
      _savings = incomes - expenses;
      _monthlySummaries = monthlySummaries;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(string.AppStrings.appName),
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
                'Last 12 Months',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.AppColor.main1Color,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                icon: const Icon(Icons.money_off),
                label: const Text('Expense'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseScreen(),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.AppColor.main1Color,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                icon: const Icon(Icons.attach_money),
                label: const Text('Income'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncomeScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Savings',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.AppColor.blackColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: Container(
                        width: width * 0.85,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color.AppColor.gray2Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              child: Center(
                                child: Text(
                                  _showAmount
                                      ? NumberFormat('#,##0').format(_savings)
                                      : "****",
                                  style: TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: color.AppColor.blackColor,
                                  ),
                                ),
                              ),
                              onDoubleTap: () {
                                setState(() {
                                  _showAmount = !_showAmount;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            InkWell(
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
                              onTap: () {
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.AppColor.blackColor,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Month',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color.AppColor.gray1Color,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color.AppColor.gray1Color,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color.AppColor.gray1Color,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Savings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color.AppColor.gray1Color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListView.builder(
                        itemCount: _monthlySummaries.length,
                        itemBuilder: (context, index) {
                          final month = _monthlySummaries[index];
                          final isPositiveSavings =
                              (month['savings'] as double) >= 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                // Month Column
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    month['month'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: color.AppColor.gray1Color,
                                    ),
                                  ),
                                ),

                                // Income Column
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _showAmount
                                          ? NumberFormat('#,##0')
                                              .format(month['total_income'])
                                          : "****",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ),

                                // Expense Column
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _showAmount
                                          ? NumberFormat('#,##0')
                                              .format(month['total_expense'])
                                          : "****",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),

                                // Savings Column
                                Expanded(
                                  flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _showAmount
                                          ? NumberFormat('#,##0')
                                              .format(month['savings'])
                                          : "****",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isPositiveSavings
                                            ? Colors.green
                                            : Colors.red,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CategoryScreen()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PersonScreen()));
          }
        },
        selectedItemColor: color.AppColor.main1Color,
        unselectedItemColor: color.AppColor.gray1Color,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Person',
          ),
        ],
      ),
    );
  }
}
