import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../models/salariedPerson.dart';
import '../widgets/dbHelper.dart';
import '../helper/colors.dart' as color;

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
                person == null ? 'Add Person' : 'Edit Person',
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
                  labelText: 'Person Name',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salaried Persons'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
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
                child: ListView.builder(
                  itemCount: _persons.length,
                  itemBuilder: (context, index) {
                    final person = _persons[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[50],
                      child: ListTile(
                        title: Text(
                          person.title,
                          style: TextStyle(color: color.AppColor.gray1Color),
                        ),
                        trailing: InkWell(
                          child: Text(
                            _showSalary
                                ? NumberFormat('#,##0')
                                    .format(_fetchPersonSalary(person.id!))
                                : "****",
                            style: TextStyle(
                              color: color.AppColor.main1Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onDoubleTap: () {
                            setState(() {
                              _showSalary = !_showSalary;
                            });
                          },
                        ),
                        onLongPress: () => _showPersonDialog(person: person),
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
              child: const Text('Add Person'),
              onPressed: () => _showPersonDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
