import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String? _selectedCategory;
  List<Map<String, dynamic>> _rankingItems = [];
  final TextEditingController _categoryController = TextEditingController();

  Future<void> _fetchRankingItems() async {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ranking')
        .where('category', isEqualTo: _selectedCategory)
        .orderBy('record', descending: true)
        .get();

    List<Map<String, dynamic>> rankingItems = snapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    setState(() {
      _rankingItems = rankingItems;
    });
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
        title: const Text('Ranking'),
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
                    decoration: const InputDecoration(
                      labelText: 'Enter Category',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
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
                    title: Text(item['user']),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('記録: ${item['record']}'),
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
