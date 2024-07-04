import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'camera_screen.dart'; // カメラ画面のインポートを追加
import 'package:camera/camera.dart'; // カメラパッケージのインポート

class GoalsScreen extends StatefulWidget {
  final CameraDescription camera;

  GoalsScreen({required this.camera}); // コンストラクタに camera を追加

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _selectedGoal = '筋トレ';
  List<String> _goals = [];
  Map<String, String> _goalUnits = {};

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
    _fetchGoals();
  }

  Future<void> _initializeFirestore() async {
    final firestore = FirebaseFirestore.instance;

    // Firestoreの初期化部分
    await firestore.collection('goals').get().then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    final List<Map<String, String>> presetGoals = [
      {'goal': '筋トレ', 'unit': '分'},
      {'goal': '英単語', 'unit': '語'},
    ];

    for (var goalData in presetGoals) {
      String goal = goalData['goal']!;
      String unit = goalData['unit']!;

      await firestore.collection('goals').doc(goal).set({
        'goal': goal,
        'unit': unit,
      }, SetOptions(merge: true)); // 既存のデータを保持しつつ追加・更新
    }
  }

  void _fetchGoals() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('goals').get();

    setState(() {
      _goals = snapshot.docs.map((doc) => doc.id).toList();
      _goalUnits = {for (var doc in snapshot.docs) doc.id: doc['unit']};
      if (_goals.isNotEmpty) {
        _selectedGoal = _goals.first;
      }
    });
  }

  void _saveRecord(String value) async {
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('値を入力してください')),
      );
      return;
    }

    String date = DateTime.now().toIso8601String().split('T').first;

    await FirebaseFirestore.instance.collection('records').add({
      'goal': _selectedGoal,
      'value': value,
      'date': date,
    });

    Navigator.of(context).pop(); // ダイアログを閉じる
  }

  void _addGoal(String goalName, String goalUnit) async {
    await FirebaseFirestore.instance.collection('goals').doc(goalName).set({
      'goal': goalName,
      'unit': goalUnit,
    });

    setState(() {
      _goals.add(goalName);
      _goalUnits[goalName] = goalUnit;
    });

    Navigator.of(context).pop(); // ダイアログを閉じる
  }

  void _deleteGoal(String goalName) async {
    final firestore = FirebaseFirestore.instance;

    // 目標を削除
    await firestore.collection('goals').doc(goalName).delete();

    // 関連する記録も削除
    final recordsSnapshot = await firestore
        .collection('records')
        .where('goal', isEqualTo: goalName)
        .get();
    for (var doc in recordsSnapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _goals.remove(goalName);
      _goalUnits.remove(goalName);
      if (_selectedGoal == goalName && _goals.isNotEmpty) {
        _selectedGoal = _goals.first;
      } else if (_goals.isEmpty) {
        _selectedGoal = '';
      }
    });
  }

  void _showInputDialog(
      {required String title, required Function(String) onSave}) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: '値を入力してください'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                onSave(_controller.text);
              },
              child: Text('保存'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  void _showAddGoalDialog() {
    final TextEditingController _goalNameController = TextEditingController();
    final TextEditingController _goalUnitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('目標を追加する'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _goalNameController,
                decoration: InputDecoration(labelText: '目標名を入力してください'),
              ),
              TextField(
                controller: _goalUnitController,
                decoration: InputDecoration(labelText: '単位を入力してください'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _addGoal(_goalNameController.text, _goalUnitController.text);
              },
              child: Text('追加'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('目標トラッカー'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CameraScreen(camera: widget.camera), // カメラ画面に遷移
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_goals.isNotEmpty)
            DropdownButton<String>(
              value: _selectedGoal,
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) {
                    _selectedGoal = newValue;
                  }
                });
              },
              items: _goals.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ElevatedButton(
            onPressed: () {
              _showInputDialog(
                title: '値を入力してください',
                onSave: _saveRecord,
              );
            },
            child: Text('記録を保存する'),
          ),
          Expanded(
            child: _buildRecordsTable(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _showAddGoalDialog,
                  child: Text('目標を追加する'),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    String goal = _goals[index];
                    return ListTile(
                      title: Text('$goal (${_goalUnits[goal]})'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteGoal(goal);
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedGoal = goal;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTable() {
    if (_selectedGoal.isEmpty) {
      return Center(child: Text('記録がありません'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('records')
          .where('goal', isEqualTo: _selectedGoal)
          .orderBy('date') // 日付順に並べる
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> records = snapshot.data!.docs;
        if (records.isEmpty) {
          return Center(child: Text('記録がありません'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('日付')),
              DataColumn(label: Text('値'))
            ],
            rows: records.map((record) {
              String date = record.get('date') ?? '日付なし';
              String value = record.get('value') ?? '0';
              return DataRow(cells: [
                DataCell(Text(date)),
                DataCell(Text(value + ' ' + (_goalUnits[_selectedGoal] ?? ''))),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}
