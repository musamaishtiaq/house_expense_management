import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../models/salariedPerson.dart';
import '../widgets/dbHelper.dart';
import '../helper/colors.dart' as color;

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  List<Income> _incomes = [];
  List<Income> _filteredIncomes = [];
  List<SalariedPerson> _salariedPersons = [];
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  SalariedPerson? _selectedPerson;
  Income? _editingIncome;
  bool _showAggregated = false;
  final DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
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
    final incomes = await _dbHelper.getLast3MonthsIncomes();
    final persons = await _dbHelper.getAllSalariedPersons();
    setState(() {
      _incomes = incomes;
      _applyFilter();
      _salariedPersons = persons;
      if (persons.isNotEmpty && _selectedPerson == null) {
        _selectedPerson = persons.first;
      }
    });
  }

  void _applyFilter() {
    if (_showAggregated) {
      // Create monthly aggregates
      final Map<String, Income> monthlyAggregates = {};

      // List of target months (current + past 2)
      final List<DateTime> targetMonths = List.generate(3, (i) {
        final month = _currentDate.month - i;
        final year = _currentDate.year;
        return DateTime(year, month);
      });

      for (final income in _incomes) {
      final incomeMonth = DateTime(income.dateTime.year, income.dateTime.month);

      // Check if the income is from any of the target months
      if (targetMonths.any((m) => m.year == incomeMonth.year && m.month == incomeMonth.month)) {
        final key = '${income.salariedPersonId}_${incomeMonth.year}_${incomeMonth.month}';

        if (monthlyAggregates.containsKey(key)) {
          monthlyAggregates[key]!.amount += income.amount;
        } else {
          monthlyAggregates[key] = Income(
            id: income.salariedPersonId, // key as unique ID (string)
            salariedPersonId: income.salariedPersonId,
            amount: income.amount,
            dateTime: incomeMonth,
            description: 'Monthly Total',
          );
        }
      }
    }

      _filteredIncomes = monthlyAggregates.values.toList();
    } else {
      // Show all entries
      _filteredIncomes = List.from(_incomes);
    }
  }

  void _toggleFilter() {
    setState(() {
      _showAggregated = !_showAggregated;
      _applyFilter();
    });
  }

  void _showIncomeDialog({Income? income}) {
    _editingIncome = income;
    _selectedDate = income?.dateTime ?? DateTime.now();
    _dateController.text =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    _amountController.text = income?.amount.toStringAsFixed(0) ?? '';
    _descriptionController.text = income?.description ?? '';
    _selectedPerson = _salariedPersons.firstWhere(
      (person) => person.id == income?.salariedPersonId,
      orElse: () => _salariedPersons.first,
    );

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
                      income == null ? 'Add Income' : 'Edit Income',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color.AppColor.main1Color,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Salaried Person Dropdown
                    DropdownButtonFormField<SalariedPerson>(
                      value: _selectedPerson,
                      decoration: InputDecoration(
                        labelText: 'Salaried Person',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _salariedPersons.map((person) {
                        return DropdownMenuItem<SalariedPerson>(
                          value: person,
                          child: Text(person.title),
                        );
                      }).toList(),
                      onChanged: (person) {
                        setState(() {
                          _selectedPerson = person;
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
                            if (_selectedPerson == null ||
                                _amountController.text.isEmpty) return;

                            final amount =
                                double.tryParse(_amountController.text) ?? 0;

                            if (_editingIncome == null) {
                              await _dbHelper.insertIncome(
                                Income(
                                  salariedPersonId: _selectedPerson!.id!,
                                  amount: amount,
                                  dateTime: _selectedDate,
                                  description:
                                      _descriptionController.text.trim(),
                                ),
                              );
                            } else {
                              await _dbHelper.updateIncome(
                                Income(
                                  id: _editingIncome!.id,
                                  salariedPersonId: _selectedPerson!.id!,
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

  Future<void> _deleteIncome(int id) async {
    await _dbHelper.deleteIncome(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Records'),
        actions: [
          IconButton(
            icon: Icon(
              _showAggregated ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.black,
            ),
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
                  _buildIncomeList(),
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
                    child: const Text('Add Income'),
                    onPressed: () => _showIncomeDialog(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeList() {
    if (_filteredIncomes.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No income records yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _filteredIncomes.length,
        itemBuilder: (context, index) {
          final income = _filteredIncomes[index];
          final person = _salariedPersons.firstWhere(
            (p) => p.id == income.salariedPersonId,
            orElse: () => SalariedPerson(title: 'Unknown'),
          );

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.grey[50],
            child: ListTile(
              title: Text(person.title),
              subtitle: Text(
                _showAggregated
                    ? '${income.dateTime.month}/${income.dateTime.year}'
                    : '${income.dateTime.day}/${income.dateTime.month}/${income.dateTime.year}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat('#,##0').format(income.amount),
                    style: TextStyle(
                      color: color.AppColor.main1Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (income.description?.isNotEmpty ?? false)
                    Text(
                      income.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              onLongPress: () =>
                  _showAggregated ? {} : _showIncomeDialog(income: income),
            ),
          );
        },
      ),
    );
  }
}
