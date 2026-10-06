import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'helper/appTheme.dart';
import 'helper/strings.dart' as string;
import 'screens/appShell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: string.AppStrings.appName,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
