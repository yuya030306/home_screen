import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_goal_from_preset_screen.dart';  // 新しい画面のインポート

class GoalScreen extends StatefulWidget {
  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('goals').get();
    setState(() {
      _goals = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'goal': data['goal'],
          'unit': data['unit'],
          'value': data['value'],
          'deadline': (data['deadline'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目標管理'),
      ),
      body: ListView.builder(
        itemCount: _goals.length,
        itemBuilder: (context, index) {
          final goal = _goals[index];
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goal: ${goal['goal']}'),
                Text('Value: ${goal['value']} ${goal['unit']}'),
                Text('Deadline: ${goal['deadline']}'),
              ],
            ),
            // onTapを削除して目標をタップしても編集できないようにする
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGoalFromPresetScreen()),
          ).then((_) => _loadGoals()); // 戻った後に目標をリロード
        },
      ),
    );
  }
}
