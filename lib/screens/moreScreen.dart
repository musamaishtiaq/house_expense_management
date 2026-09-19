import 'package:flutter/material.dart';

import '../helper/colors.dart' as color;
import 'expenseInsightScreen.dart';
import 'settingsScreen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
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
                'Options',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[50],
                    child: ListTile(
                      title: Text(
                        'Expense Insight',
                        style: TextStyle(color: color.AppColor.gray1Color),
                      ),
                      subtitle: Text(
                        'Basic need vs actual spending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: color.AppColor.main1Color,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ExpenseInsightScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[50],
                    child: ListTile(
                      title: Text(
                        'Settings',
                        style: TextStyle(color: color.AppColor.gray1Color),
                      ),
                      subtitle: Text(
                        'Hint months and savings target',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: color.AppColor.main1Color,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
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
