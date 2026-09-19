import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helper/colors.dart' as color;
import '../models/appSettings.dart';
import '../widgets/dbHelper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ExpenseDbHelper _dbHelper = ExpenseDbHelper();
  final TextEditingController _savingsController = TextEditingController();

  static const List<int> _hintMonthOptions = [3, 6, 9, 12];

  AppSettings _settings = AppSettings();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final settings = await _dbHelper.getAppSettings();
    final months = _hintMonthOptions.contains(settings.hintMonths)
        ? settings.hintMonths
        : 3;

    if (!mounted) return;
    setState(() {
      _settings = AppSettings(
        id: settings.id,
        hintMonths: months,
        monthlySavingsTarget: settings.monthlySavingsTarget,
      );
      _savingsController.text = settings.monthlySavingsTarget == 0
          ? ''
          : settings.monthlySavingsTarget.toStringAsFixed(
              settings.monthlySavingsTarget.truncateToDouble() ==
                      settings.monthlySavingsTarget
                  ? 0
                  : 2,
            );
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final raw = _savingsController.text.trim();
    final target = raw.isEmpty ? 0.0 : double.tryParse(raw);

    if (target == null || target < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid savings target')),
      );
      return;
    }

    setState(() => _saving = true);

    final updated = AppSettings(
      id: _settings.id,
      hintMonths: _settings.hintMonths,
      monthlySavingsTarget: target,
    );
    await _dbHelper.updateAppSettings(updated);

    if (!mounted) return;
    setState(() {
      _settings = updated;
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(seconds: 1),
      ),
    );
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

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _sectionBar('Expense Insight'),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default months for basic need',
                        style: TextStyle(color: color.AppColor.gray1Color),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: DropdownButtonFormField<int>(
                            value: _settings.hintMonths,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            items: _hintMonthOptions
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text('$m months'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _settings = AppSettings(
                                  id: _settings.id,
                                  hintMonths: value,
                                  monthlySavingsTarget:
                                      _settings.monthlySavingsTarget,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionBar('Savings'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly savings target',
                          style: TextStyle(color: color.AppColor.gray1Color),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.grey[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextField(
                              controller: _savingsController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              decoration:
                                  _fieldDecoration('Savings target amount'),
                              cursorColor: color.AppColor.blackColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.AppColor.main1Color,
                            foregroundColor: color.AppColor.whiteColor,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: _saving ? null : _saveSettings,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
