import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'camera_screen.dart'; // カメラ画面のインポートを追加
import 'package:camera/camera.dart'; // カメラパッケージのインポート

class RecordGoalsScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;

  RecordGoalsScreen({required this.camera, required this.userId});
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
      await _firestore.collection('records').add({
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
        title: Text('目標入力画面'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CameraScreen(camera: widget.camera, userId: widget.userId), // カメラ画面に遷移
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _goalController,
              decoration: InputDecoration(labelText: '達成した目標'),
            ),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(labelText: '数値'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRecord,
              child: Text('保存する'),
            ),
          ],
        ),
      ),
    );
  }
}
