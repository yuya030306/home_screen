import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordGoalsScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;
  final DocumentSnapshot goal;

  RecordGoalsScreen(
      {required this.camera, required this.userId, required this.goal});

  @override
  _RecordGoalsScreenState createState() => _RecordGoalsScreenState();
}

class _RecordGoalsScreenState extends State<RecordGoalsScreen> {
  final TextEditingController _valueController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isDeadlinePassed = false;

  @override
  void initState() {
    super.initState();
    _checkDeadline();
  }

  Future<void> _checkDeadline() async {
    DateTime deadline = (widget.goal['deadline'] as Timestamp).toDate();
    if (deadline.isBefore(DateTime.now())) {
      setState(() {
        _isDeadlinePassed = true;
      });
    }
  }

  Future<void> _saveRecord() async {
    String value = _valueController.text;
    User? user = _auth.currentUser;

    if (value.isNotEmpty && user != null) {
      await _firestore.collection('records').add({
        'goal': widget.goal['goal'],
        'value': value,
        'timestamp': Timestamp.now(),
        'userId': user.uid,
      });

      await _firestore.collection('goals').doc(widget.goal.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record saved and goal deleted successfully!')),
      );

      _valueController.clear();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('目標達成入力'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Colors.orange,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 文字を左揃えに変更
            children: [
              Text(
                '目標: ${widget.goal['goal']}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '締切: ${DateFormat('HH:mm').format((widget.goal['deadline'] as Timestamp).toDate())}',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: '達成した数値',
                  labelStyle: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold), // ラベルの色をオレンジに変更
                  fillColor: Colors.orange[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.black), // 入力文字の色を変更
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveRecord,
                child: Text('保存する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isDeadlinePassed
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(
                              camera: widget.camera,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                icon: Icon(Icons.camera_alt, color: Colors.white),
                label: Text('カメラを起動'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isDeadlinePassed ? Colors.black : Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
