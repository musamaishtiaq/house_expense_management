import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../models/salariedPerson.dart';
import '../helper/colors.dart';
import '../widgets/appWidgets.dart';
import '../widgets/dbHelper.dart';

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
  int? _expandedPersonId;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month, now.day);
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _loadData() async {
    final start = _dateOnly(_rangeStart);
    final endExclusive = _dateOnly(_rangeEnd).add(const Duration(days: 1));
    final incomes = await _dbHelper.getIncomesByDateRange(start, endExclusive);
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
      final Map<int, Income> aggregates = {};
      for (final income in _incomes) {
        final key = income.salariedPersonId;
        if (aggregates.containsKey(key)) {
          aggregates[key]!.amount += income.amount;
        } else {
          aggregates[key] = Income(
            id: income.salariedPersonId,
            salariedPersonId: income.salariedPersonId,
            amount: income.amount,
            dateTime: income.dateTime,
            description: 'Range Total',
          );
        }
      }
      _filteredIncomes = aggregates.values.toList();
    } else {
      _filteredIncomes = List.from(_incomes);
    }
  }

  Future<void> _pickRangeDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _rangeStart : _rangeEnd,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColor.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _rangeStart = _dateOnly(picked);
        if (_rangeStart.isAfter(_rangeEnd)) {
          _rangeEnd = _rangeStart;
        }
      } else {
        _rangeEnd = _dateOnly(picked);
        if (_rangeEnd.isBefore(_rangeStart)) {
          _rangeStart = _rangeEnd;
        }
      }
    });
    await _loadData();
  }

  void _toggleFilter() {
    setState(() {
      _showAggregated = !_showAggregated;
      _expandedPersonId = null;
      _applyFilter();
    });
  }

  void _togglePersonExpand(int personId) {
    setState(() {
      _expandedPersonId = _expandedPersonId == personId ? null : personId;
    });
  }

  Future<void> _showIncomeDialog({Income? income}) async {
    _editingIncome = income;
    final persons = await _dbHelper.getAllSalariedPersons();
    if (!mounted) return;
    _salariedPersons = persons;

    _selectedDate = income?.dateTime ?? DateTime.now();
    _dateController.text =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    _amountController.text = income?.amount.toStringAsFixed(0) ?? '';
    _descriptionController.text = income?.description ?? '';
    if (persons.isEmpty) {
      _selectedPerson = null;
    } else {
      _selectedPerson = persons.firstWhere(
        (person) => person.id == income?.salariedPersonId,
        orElse: () => persons.first,
      );
    }

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
                        primary: AppColor.primary, // Header color
                        onPrimary: Colors.white, // Header text color
                        onSurface: Colors.black, // Calendar text color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColor.primary, // Button color
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
              backgroundColor: AppColor.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Salaried Person Dropdown
                    DropdownButtonFormField<SalariedPerson>(
                      value: _selectedPerson,
                      decoration:
                          appInputDecoration(label: 'Salaried Person'),
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
                      decoration: appInputDecoration(
                        label: 'Amount',
                        prefixText: 'Rs ',
                      ),
                      cursorColor: AppColor.textPrimary,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: appInputDecoration(
                        label: 'Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: AppColor.primary),
                          onPressed: selectDate,
                        ),
                      ),
                      onTap: selectDate,
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      decoration: appInputDecoration(
                        label: 'Description (Optional)',
                      ),
                      cursorColor: AppColor.textPrimary,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
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
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: const Text('Income Records'),
        actions: [
          IconButton(
            icon: Icon(
              _showAggregated ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: _toggleFilter,
            tooltip: _showAggregated
                ? 'Show All Entries'
                : 'Show Person Totals',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildRangeDateField(
                    label: 'Start',
                    date: _rangeStart,
                    onTap: () => _pickRangeDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRangeDateField(
                    label: 'End',
                    date: _rangeEnd,
                    onTap: () => _pickRangeDate(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _buildIncomeList(),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Add Income',
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

          if (_showAggregated) {
            return _buildAggregatedIncomeCard(income, person);
          }

          return AppCard(
            onLongPress: () => _showIncomeDialog(income: income),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.title,
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${income.dateTime.day}/${income.dateTime.month}/${income.dateTime.year}',
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat('#,##0').format(income.amount),
                      style: const TextStyle(
                        color: AppColor.income,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (income.description?.isNotEmpty ?? false)
                      Text(
                        income.description!,
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAggregatedIncomeCard(Income income, SalariedPerson person) {
    final isExpanded = _expandedPersonId == income.salariedPersonId;
    final entries = _entriesForPerson(income.salariedPersonId);

    return AppCard(
      onTap: () => _togglePersonExpand(income.salariedPersonId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  person.title,
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
                    NumberFormat('#,##0').format(income.amount),
                    style: const TextStyle(
                      color: AppColor.income,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${entries.length} entries',
                    style: const TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColor.textSecondary,
              ),
            ],
          ),
          if (isExpanded)
            ...entries.map((entry) {
              return InkWell(
                onLongPress: () => _showIncomeDialog(income: entry),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year}',
                          style: const TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        NumberFormat('#,##0').format(entry.amount),
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRangeDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
          ),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(
              color: AppColor.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Income> _entriesForPerson(int personId) {
    return _incomes.where((e) => e.salariedPersonId == personId).toList();
  }
}
