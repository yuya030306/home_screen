import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordGoalsScreen extends StatefulWidget {
  @override
  _RecordGoalsScreenState createState() => _RecordGoalsScreenState();
}

class _RecordGoalsScreenState extends State<RecordGoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveRecord() async {
    String goal = _goalController.text;
    String value = _valueController.text;

    if (goal.isNotEmpty && value.isNotEmpty) {
      await _firestore.collection('goalRecords').add({
        'goal': goal,
        'value': value,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved successfully!')),
      );

      _goalController.clear();
      _valueController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Goals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              decoration: InputDecoration(labelText: 'Goal'),
            ),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(labelText: 'Value'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRecord,
              child: Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}
