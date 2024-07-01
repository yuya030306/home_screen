import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalCard extends StatelessWidget {
  final DocumentSnapshot goal;
  final Function({DocumentSnapshot? goal}) showGoalDialog;

  GoalCard({required this.goal, required this.showGoalDialog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(goal['goal']),
        subtitle: Text('Deadline: ${goal['deadline'].toDate()}'),
        trailing: IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => showGoalDialog(goal: goal),
        ),
      ),
    );
  }
}
