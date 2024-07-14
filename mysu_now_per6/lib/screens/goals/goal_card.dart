import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../record_goals.dart';
import 'package:camera/camera.dart'; // カメラパッケージのインポート

class GoalCard extends StatelessWidget {
  final DocumentSnapshot goal;
  final Function({DocumentSnapshot? goal}) showGoalDialog;
  final String value;
  final String unit;
  final CameraDescription camera; // カメラ情報を追加
  final String userId; // ユーザーIDを追加

  GoalCard({
    required this.goal,
    required this.showGoalDialog,
    required this.value,
    required this.unit,
    required this.camera, // カメラ情報を追加
    required this.userId, // ユーザーIDを追加
  });

  @override
  Widget build(BuildContext context) {
    DateTime deadline = (goal['deadline'] as Timestamp).toDate();

    // 締め切りが過ぎた目標は表示しない
    if (deadline.isBefore(DateTime.now())) {
      return SizedBox.shrink();
    }

    return Card(
      child: ListTile(
        title: Text(goal['goal']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value $unit'),
            Text('締切: ${DateFormat('kk:mm').format(deadline)}まで'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordGoalsScreen(camera: camera, userId: userId, goal: goal),
            ),
          );
        },
      ),
    );
  }
}
