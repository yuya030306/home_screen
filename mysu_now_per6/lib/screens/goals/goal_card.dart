import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalCard extends StatelessWidget {
  final DocumentSnapshot goal;
  final Function({DocumentSnapshot? goal}) showGoalDialog;
  final String value;
  final String unit;

  GoalCard({required this.goal, required this.showGoalDialog, required this.value, required this.unit});

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
        onTap: () {}, // 目標をタップしても何も起こらないようにする
      ),
    );
  }
}
