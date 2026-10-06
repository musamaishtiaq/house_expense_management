import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helper/colors.dart';
import '../models/appSettings.dart';
import '../widgets/appWidgets.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.pageBackground,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionLabel('Expense Insight'),
                  const Text(
                    'Default months for basic need',
                    style: TextStyle(color: AppColor.textSecondary),
                  ),
                  AppCard(
                    child: DropdownButtonFormField<int>(
                      value: _settings.hintMonths,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
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
                  const AppSectionLabel('Savings'),
                  const Text(
                    'Monthly savings target',
                    style: TextStyle(color: AppColor.textSecondary),
                  ),
                  AppCard(
                    child: TextField(
                      controller: _savingsController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Savings target amount',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      cursorColor: AppColor.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
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
                  ),
                ],
              ),
            ),
    );
  }
}
