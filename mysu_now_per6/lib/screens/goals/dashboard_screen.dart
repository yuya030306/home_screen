import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import 'goal_card.dart';
import 'add_goal_from_preset_screen.dart';
import '../record_goals.dart';

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
                    .where('userId', isEqualTo: widget.userId)
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
                      Map<String, dynamic> goalData = goal.data() as Map<String, dynamic>;
                      final isAchieved = goalData['isAchieved'] ?? false;
                      DateTime deadline = (goal['deadline'] as Timestamp).toDate();
                      bool isPastDeadline = deadline.isBefore(DateTime.now());
                      Color cardColor = isPastDeadline ? Colors.grey.shade300 : Colors.white;
                      cardColor = isAchieved ? Colors.green.shade100 : cardColor;

                      return Card(
                        color: cardColor,
                        child: ListTile(
                          title: Text(goal['goal']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${goal['value']} ${goal['unit']}'),
                              Text('締切: ${DateFormat('kk:mm').format(deadline)}まで'),
                            ],
                          ),
                          onTap: isAchieved ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordGoalsScreen(
                                  camera: widget.camera,
                                  userId: widget.userId,
                                  goal: goal,
                                  isPastDeadline: isPastDeadline,
                                ),
                              ),
                            );
                          },
                        ),
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
