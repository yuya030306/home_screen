import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_data.dart';
import 'ranking.dart';


void main() async {
  // Flutterアプリの初期化を確実にするためにWidgetsFlutterBinding.ensureInitialized()を呼び出します.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebaseを初期化します。
  await Firebase.initializeApp();
  // アプリを実行します。
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ranking App',
      theme: ThemeData(
        // アプリのテーマを設定します。ここでは深い紫を基調とした色のテーマを使用します。
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // アプリのホーム画面としてHomeScreenウィジェットを設定します。
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 現在選択されているタブのインデックスを保持します。
  int _selectedIndex = 0;

  // 各タブで表示するウィジェットをリストで定義します。
  static const List<Widget> _widgetOptions = <Widget>[
    AddDataScreen(),// データ追加画面
    RankingScreen(),// ランキング画面
  ];

  // ボトムナビゲーションバーのアイテムがタップされたときに呼び出されます。
  void _onItemTapped(int index) {
    setState(() {
      print('Selected index: $index'); // デバッグ用のprintステートメント
      // タップされたアイテムのインデックスを更新します。
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 現在選択されているインデックスに応じて、表示するウィジェットを決定します。
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add),// データ追加タブのアイコン
            label: 'Add Record',// データ追加タブのラベル
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),// ランキングタブのアイコン
            label: 'Ranking',// ランキングタブのラベル
          ),
        ],
        // 現在選択されているタブのインデックスを設定します。
        currentIndex: _selectedIndex,
        // 選択されたタブのアイコンの色を設定します。
        selectedItemColor: Colors.deepPurple,
        // アイテムがタップされたときに_onItemTappedメソッドを呼び出します。
        onTap: _onItemTapped,
      ),
    );
  }
}
