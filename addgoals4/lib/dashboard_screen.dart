import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'goal_card.dart';
import 'add_goal_from_preset_screen.dart';  // 新しい画面のインポート

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('目標管理'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('goals')
                  .where('deadline', isGreaterThan: Timestamp.now())
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('進行中の目標がありません'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var goal = snapshot.data!.docs[index];
                    return GoalCard(
                      goal: goal,
                      showGoalDialog: ({DocumentSnapshot? goal}) => {},  // 目標をタップしても編集できないようにする
                      value: goal['value'],
                      unit: goal['unit'],
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddGoalFromPresetScreen()),
              ).then((_) => setState(() {}));  // AddGoalFromPresetScreenから戻った際に画面を更新
            },
            child: Text('目標を追加する'),
          ),
        ],
      ),
    );
  }
}
