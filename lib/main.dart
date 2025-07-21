import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helper/colors.dart' as color;
import '../helper/strings.dart' as string;
import '../screens/homeScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: string.AppStrings.appName,
      theme: ThemeData(
        primarySwatch: color.AppColor.primarySwatchColor,
        fontFamily: 'Quicksand',
        textTheme: ThemeData.light().textTheme.copyWith(
            bodyLarge: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                color: color.AppColor.blackColor),
            bodyMedium: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                color: color.AppColor.whiteColor)),
        appBarTheme: AppBarTheme(
            titleTextStyle: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.AppColor.blackColor)),
      ),
      home: const HomeScreen(),
    );
  }
}
