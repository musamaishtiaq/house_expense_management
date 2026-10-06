import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../models/salariedPerson.dart';
import '../helper/colors.dart';
import '../widgets/appWidgets.dart';
import '../widgets/dbHelper.dart';

class PersonScreen extends StatefulWidget {
  const PersonScreen({super.key});
  @override
  _PersonScreenState createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  List<SalariedPerson> _persons = [];
  Map<int, Income> _monthlySalary = {};
  final TextEditingController _titleController = TextEditingController();
  SalariedPerson? _editingPerson;
  bool _showSalary = false;
  final DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPersons();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadPersons() async {
    final persons = await _dbHelper.getAllSalariedPersons();
    setState(() {
      _persons = persons;
    });
  }

  Future<void> _loadData() async {
    final incomes = await _dbHelper.getCurrentMonthIncome();
    final Map<int, Income> monthlyAggregates = {};
    for (final income in incomes) {
      // Check if same month and year as current
      if (income.dateTime.year == _currentDate.year &&
          income.dateTime.month == _currentDate.month) {
        if (monthlyAggregates.containsKey(income.salariedPersonId)) {
          // Add to existing aggregate
          monthlyAggregates[income.salariedPersonId]!.amount += income.amount;
        } else {
          // Create new aggregate
          monthlyAggregates[income.salariedPersonId] = Income(
            id: income.salariedPersonId,
            salariedPersonId: income.salariedPersonId,
            amount: income.amount,
            dateTime: DateTime(_currentDate.year, _currentDate.month),
            description: 'Monthly Total',
          );
        }
      }
    }
    setState(() {
      _monthlySalary = monthlyAggregates;
    });
  }

  double _fetchPersonSalary(int personId) {
    return (_monthlySalary.containsKey(personId))
        ? _monthlySalary[personId]!.amount
        : 0;
  }

  void _showPersonDialog({SalariedPerson? person}) {
    _editingPerson = person;
    _titleController.text = person?.title ?? '';

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
                person == null ? 'Add Person' : 'Edit Person',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: appInputDecoration(label: 'Person Name'),
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

                      if (_editingPerson == null) {
                        await _dbHelper.insertSalariedPerson(
                          SalariedPerson(
                            title: _titleController.text.trim(),
                          ),
                        );
                      } else {
                        await _dbHelper.updateSalariedPerson(
                          SalariedPerson(
                            id: _editingPerson!.id,
                            title: _titleController.text.trim(),
                          ),
                        );
                      }

                      _titleController.clear();
                      Navigator.pop(context);
                      _loadPersons();
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

  Future<void> _deletePerson(int id) async {
    await _dbHelper.deleteSalariedPerson(id);
    _loadPersons();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final person = _persons.removeAt(oldIndex);
      _persons.insert(newIndex, person);
    });
    await _dbHelper.updateSalariedPersonsOrder(_persons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: const Text('Salaried Persons'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            if (_persons.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No persons added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _persons.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final person = _persons[index];
                    return AppCard(
                      key: ValueKey(person.id),
                      onLongPress: () => _showPersonDialog(person: person),
                      child: Row(
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
                              person.title,
                              style: const TextStyle(
                                color: AppColor.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onDoubleTap: () {
                              setState(() {
                                _showSalary = !_showSalary;
                              });
                            },
                            child: Text(
                              _showSalary
                                  ? NumberFormat('#,##0')
                                      .format(_fetchPersonSalary(person.id!))
                                  : '****',
                              style: const TextStyle(
                                color: AppColor.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Add Person',
              onPressed: () => _showPersonDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
