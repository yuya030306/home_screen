import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class EmailCheck extends StatefulWidget {
  final String email;
  final String pswd;
  final int from;

  EmailCheck(
      {Key? key, required this.email, required this.pswd, required this.from})
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
                      builder: (context) => Home(
                        userId: _result!.user!.uid,
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
