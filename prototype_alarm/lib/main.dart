import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'alarm.dart'; // AlarmPageをインポート
import 'graph.dart'; // GraphPageをインポート
import 'data_entry.dart'; // DataEntryPageをインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // 初期ルートを指定
      routes: {
        '/': (context) => AlarmPage(), // ルート '/' はAlarmPageにマッピング
        '/graph': (context) => GraphPage(), // ルート '/graph' はGraphPageにマッピング
        '/data-entry': (context) =>
            DataEntryPage(), // ルート '/data-entry' はDataEntryPageにマッピング
      },
    );
  }
}



// testtest
