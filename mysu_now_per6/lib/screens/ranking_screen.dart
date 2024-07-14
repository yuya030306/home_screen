import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this import

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
        primarySwatch: Colors.orange,
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
  DateTime _selectedMonth = DateTime.now(); // Add this line

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
          .collection('goals')
          .where('goal', isEqualTo: _selectedCategory)
          .get();

      if (snapshot.docs.isEmpty) {
        _showCategoryNotFoundDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, Map<String, dynamic>> userBestRecords = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? 'Unknown';

        // データのフィールドをチェックし、デフォルト値を設定
        String username = 'Unknown';
        Color avatarColor = Colors.blue;
        if (data.containsKey('userId')) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userSnapshot.exists) {
            username = userSnapshot['username'] ?? 'Unknown';
            avatarColor = (userSnapshot.data() as Map<String, dynamic>).containsKey('avatarColor')
                ? Color(int.parse(userSnapshot['avatarColor'], radix: 16))
                : Colors.blue;
          }
        }
        data['username'] = username;
        data['avatarColor'] = avatarColor;

        data['value'] = data.containsKey('value') ? double.tryParse(data['value'].toString()) ?? 0 : 0;
        data['deadline'] = data.containsKey('deadline') && data['deadline'] is Timestamp
            ? (data['deadline'] as Timestamp).toDate()
            : (data['deadline'] ?? DateTime.now());

        if (data['deadline'].month == _selectedMonth.month && data['deadline'].year == _selectedMonth.year) {
          if (!userBestRecords.containsKey(userId) || userBestRecords[userId]!['value'] < data['value']) {
            userBestRecords[userId] = data;
          }
        }
      }

      List<Map<String, dynamic>> rankingItems = userBestRecords.values.toList();

      rankingItems.sort((a, b) {
        int compare = (b['value'] as num).compareTo(a['value'] as num);
        if (compare != 0) return compare;
        compare = (a['deadline'] as DateTime).compareTo(b['deadline'] as DateTime);
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

  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + months);
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
          backgroundColor: Colors.orange,
        ),
        body: CustomPaint(
          painter: BackgroundPainter(),
          child: Column(
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
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              DateFormat.yMMMM().format(_selectedMonth),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
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
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
    BoxShadow(
    color: Colors.black12,
    blurRadius: 10,
    offset: Offset(0, 5),
    ),
    ],
    ),
    child: Row(
    children: [
    Text(
    '${index + 1}位',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    ),
    ),
    SizedBox(width: 10),
    CircleAvatar(
    backgroundColor: item['avatarColor'],
    child: Text(
    item['username'][0].toUpperCase(),
    style: TextStyle(color: Colors.white),
    ),
    ),
    SizedBox(width: 10),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    item['username'],
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
      SizedBox(height: 5),
      Text(
        '記録: ${item['value'].toInt()}',
        style: TextStyle(fontSize: 16),
      ),
      Text(
        '日付: ${DateFormat.yMMMd().format(item['deadline'] as DateTime)}',
        style: TextStyle(fontSize: 14),
      ),
    ],
    ),
    ],
    ),
    ),
    );
    },
    ),
    ),
              ],
          ),
        ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    paint.color = Colors.orange.shade200;

    path.reset();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

