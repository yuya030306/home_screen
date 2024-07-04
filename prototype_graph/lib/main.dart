import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home.dart'; // 新しいホーム画面をインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '目標トラッカー',
      home: HomeScreen(), // ホーム画面を初期画面に設定
    );
  }
}
