import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'camera_screen.dart'; // カメラ画面のインポートを追加
import 'package:camera/camera.dart'; // カメラパッケージのインポート

class RecordGoalsScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;
  final DocumentSnapshot goal; // 目標の内容を渡すためのフィールドを追加

  RecordGoalsScreen({required this.camera, required this.userId, required this.goal}); // goalを必須パラメータに追加

  @override
  _RecordGoalsScreenState createState() => _RecordGoalsScreenState();
}

class _RecordGoalsScreenState extends State<RecordGoalsScreen> {
  final TextEditingController _valueController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveRecord() async {
    String value = _valueController.text;

    if (value.isNotEmpty) {
      await _firestore.collection('records').add({
        'goal': widget.goal['goal'], // 事前に設定された目標の内容
        'value': value,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved successfully!')),
      );

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
        title: Text('目標達成入力'),
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
            Text(
              '目標: ${widget.goal['goal']}', // 目標の内容を表示
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '締切: ${DateFormat('HH:mm').format((widget.goal['deadline'] as Timestamp).toDate())}', // 締切日時を表示
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(labelText: '達成した数値'),
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
