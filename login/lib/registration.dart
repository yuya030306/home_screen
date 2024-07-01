import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication_error.dart';
import 'email_check.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _auth = FirebaseAuth.instance;
  UserCredential? _result;
  User? _user;

  String _newEmail = "";
  String _newPassword = "";
  String _infoText = "";
  bool _pswdOK = false;

  final authError = AuthenticationError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 30.0),
              child: Text(
                '新規アカウントの作成',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
              child: TextFormField(
                decoration: InputDecoration(labelText: "メールアドレス"),
                onChanged: (String value) {
                  _newEmail = value;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 10.0),
              child: TextFormField(
                decoration: InputDecoration(labelText: "パスワード（8～20文字）"),
                obscureText: true,
                maxLength: 20,
                onChanged: (String value) {
                  if (value.length >= 8) {
                    _newPassword = value;
                    _pswdOK = true;
                  } else {
                    _pswdOK = false;
                  }
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 5.0),
              child: Text(
                _infoText,
                style: TextStyle(color: Colors.red),
              ),
            ),
            ButtonTheme(
              minWidth: 350.0,
              child: ElevatedButton(
                child: Text(
                  '登録',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (_pswdOK) {
                    try {
                      _result = await _auth.createUserWithEmailAndPassword(
                        email: _newEmail,
                        password: _newPassword,
                      );

                      _user = _result?.user;
                      await _user?.sendEmailVerification();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailCheck(
                            email: _newEmail,
                            pswd: _newPassword,
                            from: 1,
                          ),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        _infoText = authError.registerErrorMsg(
                            (e as FirebaseAuthException).code);
                      });
                    }
                  } else {
                    setState(() {
                      _infoText = 'パスワードは8文字以上です。';
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
