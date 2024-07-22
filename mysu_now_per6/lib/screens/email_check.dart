import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'home_screen.dart';

class EmailCheck extends StatefulWidget {
  final String email;
  final String pswd;
  final int from;
  final CameraDescription camera;
  final String userId;
  final String username; // 追加

  EmailCheck({
    Key? key,
    required this.email,
    required this.pswd,
    required this.from,
    required this.camera,
    required this.userId,
    required this.username, // 追加
  }) : super(key: key);

  @override
  _EmailCheckState createState() => _EmailCheckState();
}

class _EmailCheckState extends State<EmailCheck> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  UserCredential? _result;
  String _nocheckText = '';
  String _sentEmailText = '';
  int _btnClickNum = 0;

  @override
  Widget build(BuildContext context) {
    if (_btnClickNum == 0) {
      if (widget.from == 1) {
        _nocheckText = '';
        _sentEmailText = '${widget.email}\nに確認メールを送信しました。';
      } else {
        _nocheckText = 'まだメール確認が完了していません。\n確認メール内のリンクをクリックしてください。';
        _sentEmailText = '';
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('メール確認'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
              child: Text(
                _nocheckText,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Text(
                _sentEmailText,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 30.0),
              child: ElevatedButton(
                onPressed: () async {
                  _result = await _auth.signInWithEmailAndPassword(
                    email: widget.email,
                    password: widget.pswd,
                  );

                  await _result?.user?.sendEmailVerification();
                  setState(() {
                    _btnClickNum++;
                    _sentEmailText = '${widget.email}\nに確認メールを送信しました。';
                  });
                },
                child: Text(
                  '確認メールを再送信',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                _result = await _auth.signInWithEmailAndPassword(
                  email: widget.email,
                  password: widget.pswd,
                );

                if (_result?.user?.emailVerified ?? false) {
                  await _firestore
                      .collection('users')
                      .doc(_result?.user?.uid)
                      .set({
                    'username': widget.username,
                    'email': widget.email,
                    'friends': [],
                    'friendRequests': [],
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        camera: widget.camera,
                        userId: widget.userId,
                        auth: _auth,
                      ),
                    ),
                  );
                } else {
                  setState(() {
                    _btnClickNum++;
                    _nocheckText = "まだメール確認が完了していません。\n確認メール内のリンクをクリックしてください。";
                  });
                }
              },
              child: Text(
                'メール確認完了',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
