import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'home_screen.dart';

class EmailCheck extends StatefulWidget {
  final String email;
  final String pswd;
  final int from;
  final CameraDescription camera;
  final String userId;

  EmailCheck(
      {Key? key,
      required this.email,
      required this.pswd,
      required this.from,
      required this.camera,
      required this.userId}) // コンストラクタに camera を追加
      : super(key: key);

  @override
  _EmailCheckState createState() => _EmailCheckState();
}

class _EmailCheckState extends State<EmailCheck> {
  final _auth = FirebaseAuth.instance;
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
              child: Text(
                _nocheckText,
                style: TextStyle(color: Colors.red),
              ),
            ),
            Text(_sentEmailText),
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        camera: widget.camera,
                        userId: widget.userId,
                        auth: _auth,
                      ), // 修正: HomeScreen に変更
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
