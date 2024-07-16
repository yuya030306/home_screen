import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import '../../theme.dart';
import 'goal_card.dart';
import 'add_goal_from_preset_screen.dart';

class DashboardScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;

  DashboardScreen({required this.camera, required this.userId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('目標管理'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
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
                        showGoalDialog: ({DocumentSnapshot? goal}) => {},
                        value: goal['value'],
                        unit: goal['unit'],
                        camera: widget.camera,
                        userId: widget.userId,
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
                ).then((_) => setState(() {}));
              },
              child: Text('目標を追加する'),
            ),
          ],
        ),
      ),
    );
  }
}
