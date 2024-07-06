import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ranking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RankingScreen(),
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

  Future<void> _fetchRankingItems() async {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      print('カテゴリが選択されていません');
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('goal', isEqualTo: _selectedCategory)
          .get();

      List<Map<String, dynamic>> rankingItems = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // アプリケーション側でソート
      rankingItems.sort((a, b) {
        int compare = (b['value'] as num).compareTo(a['value'] as num);
        if (compare != 0) return compare;
        compare = (a['date'] as String).compareTo(b['date'] as String);
        return compare;
      });

      setState(() {
        _rankingItems = rankingItems;
      });
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  void _onCategoryChanged() {
    setState(() {
      _selectedCategory = _categoryController.text.trim();
      _fetchRankingItems();
    });
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
          if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _rankingItems.length,
                itemBuilder: (context, index) {
                  final item = _rankingItems[index];
                  return ListTile(
                    leading: Text('${index + 1}位'),
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
