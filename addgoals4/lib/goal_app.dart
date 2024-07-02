import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class GoalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange),
        scaffoldBackgroundColor: Colors.grey[200],
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
      ),
      home: DashboardScreen(),  // アプリのホーム画面としてDashboardScreenを設定
    );
  }
}
