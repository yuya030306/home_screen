import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../record_goals.dart';
import 'package:camera/camera.dart';

class GoalCard extends StatelessWidget {
  final DocumentSnapshot goal;
  final Function({DocumentSnapshot? goal}) showGoalDialog;
  final String value;
  final String unit;
  final CameraDescription camera;
  final String userId;

  GoalCard({
    required this.goal,
    required this.showGoalDialog,
    required this.value,
    required this.unit,
    required this.camera,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    DateTime deadline = (goal['deadline'] as Timestamp).toDate();
    bool isPastDeadline = deadline.isBefore(DateTime.now());
    Map<String, dynamic> goalData = goal.data() as Map<String, dynamic>;
    bool isAchieved = goalData['isAchieved'] ?? false;
    Color cardColor = isPastDeadline ? Colors.grey.shade300 : Colors.white;
    cardColor = isAchieved ? Colors.green.shade100 : cardColor;

    return Card(
      color: cardColor,
      child: ListTile(
        title: Text(goal['goal']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value $unit'),
            Text('締切: ${DateFormat('kk:mm').format(deadline)}まで'),
          ],
        ),
        onTap: isAchieved ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordGoalsScreen(
                camera: camera,
                userId: userId,
                goal: goal,
                isPastDeadline: isPastDeadline,
              ),
            ),
          );
        },
      ),
    );
  }
}
