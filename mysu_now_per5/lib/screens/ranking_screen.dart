import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ranking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    // AddDataScreen(), // データ入力部分のコードは除外
    RankingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Ranking',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class RankingScreen extends StatefulWidget {
  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String? _selectedCategory;
  List<Map<String, dynamic>> _rankingItems = [];
  final TextEditingController _categoryController = TextEditingController();
  bool _isLoading = false;

  Future<void> _fetchRankingItems() async {
    setState(() {
      _isLoading = true;
    });

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      print('カテゴリが選択されていません');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('goal', isEqualTo: _selectedCategory)
          .get();

      if (snapshot.docs.isEmpty) {
        _showCategoryNotFoundDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> rankingItems = await Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // ユーザ情報を取得
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .get();

        if (userSnapshot.exists) {
          data['username'] = userSnapshot['username'];
          data['avatarColor'] = userSnapshot['avatarColor'] != null
              ? Color(int.parse(userSnapshot['avatarColor'], radix: 16))
              : Colors.blue; // デフォルトカラーを設定
        } else {
          data['username'] = 'Unknown';
          data['avatarColor'] = Colors.blue;
        }

        return data;
      }).toList());

      // アプリケーション側でソート
      rankingItems.sort((a, b) {
        int compare = (b['value'] as num).compareTo(a['value'] as num);
        if (compare != 0) return compare;
        compare = (a['date'] as String).compareTo(b['date'] as String);
        return compare;
      });

      setState(() {
        _rankingItems = rankingItems;
        _isLoading = false;
      });
    } catch (e) {
      print('エラーが発生しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged() {
    setState(() {
      _selectedCategory = _categoryController.text.trim();
      _fetchRankingItems();
    });
  }

  void _showCategoryNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
        content: Text('そのカテゴリは存在しません。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ランキング'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'カテゴリーを入力',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _onCategoryChanged,
                ),
              ],
            ),
          ),
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _rankingItems.length,
                itemBuilder: (context, index) {
                  final item = _rankingItems[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item['avatarColor'],
                      child: Text(
                        item['username'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(item['goal']),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('記録: ${item['value']}'),
                        Text('日付: ${item['date']}'),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
