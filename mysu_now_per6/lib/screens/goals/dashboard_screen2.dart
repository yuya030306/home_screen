import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart'; // カメラパッケージのインポート
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthのインポート
import 'goal_card.dart';

class DashboardScreen2 extends StatefulWidget {
  final CameraDescription camera; // カメラ情報を追加

  DashboardScreen2({required this.camera}); // コンストラクタを更新

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen2> {
  late User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('User ID: ${user!.uid}'); // ユーザーIDのログ出力
    } else {
      print('No user is currently signed in.');
    }
  }

  Future<List<DocumentSnapshot>> _fetchGoals() async {
    if (user == null) {
      return [];
    }
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('goals')
        .where('userId', isEqualTo: user!.uid)
        .get();
    print('Fetched ${querySnapshot.docs.length} goals'); // クエリ結果のログ出力
    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('達成した目標を選択'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchGoals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('進行中の目標がありません'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var goal = snapshot.data![index];
                    return GoalCard(
                      goal: goal,
                      showGoalDialog: ({DocumentSnapshot? goal}) => {},
                      value: goal['value'],
                      unit: goal['unit'],
                      camera: widget.camera, // カメラ情報を渡す
                      userId: user!.uid, // ユーザーIDを渡す
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
