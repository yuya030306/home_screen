import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'goal_screen.dart';
import 'goal_card.dart';

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
                        showGoalDialog: ({DocumentSnapshot? goal}) => _showGoalDialog(context, goal: goal)
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
                MaterialPageRoute(builder: (context) => GoalScreen()),
              ).then((_) => setState(() {}));  // GoalScreenから戻った際に画面を更新
            },
            child: Text('目標を追加する'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, {DocumentSnapshot? goal}) {
    final _formKey = GlobalKey<FormState>();
    String goalText = goal != null ? goal['goal'] : '';
    DateTime? selectedDate = goal != null ? (goal['deadline'] as Timestamp).toDate() : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(goal != null ? 'Edit Goal' : 'Add Goal'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      initialValue: goalText,
                      decoration: InputDecoration(labelText: 'Goal'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a goal';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        goalText = value!;
                      },
                    ),
                    ListTile(
                      title: Text(selectedDate != null
                          ? DateFormat('yyyy-MM-dd – kk:mm').format(selectedDate!)
                          : 'Select Deadline'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(picked),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDate = DateTime(
                                  picked.year, picked.month, picked.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      if (goal != null) {
                        FirebaseFirestore.instance
                            .collection('goals')
                            .doc(goal.id)
                            .update({'goal': goalText, 'deadline': selectedDate});
                      } else {
                        FirebaseFirestore.instance
                            .collection('goals')
                            .add({'goal': goalText, 'deadline': selectedDate});
                      }
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
