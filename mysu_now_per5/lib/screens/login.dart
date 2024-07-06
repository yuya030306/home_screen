import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'authentication_error.dart';
import 'registration.dart';
import 'email_check.dart';
import 'home_screen.dart';

class Login extends StatefulWidget {
  final CameraDescription camera;

  Login({required this.camera});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _auth = FirebaseAuth.instance;
  UserCredential? _result;
  User? _user;

  String _loginEmail = "";
  String _loginPassword = "";
  String _infoText = "";

  final authError = AuthenticationError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 0),
              child: TextFormField(
                decoration: InputDecoration(labelText: "メールアドレス"),
                onChanged: (String value) {
                  _loginEmail = value;
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
                  _loginPassword = value;
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
                onPressed: () async {
                  try {
                    _result = await _auth.signInWithEmailAndPassword(
                      email: _loginEmail,
                      password: _loginPassword,
                    );

                    _user = _result?.user;

                    if (_user != null) {
                      if (_user!.emailVerified) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(camera: widget.camera, userId: _user!.uid),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmailCheck(
                              email: _loginEmail,
                              pswd: _loginPassword,
                              from: 2,
                              camera: widget.camera,
                              userId: _user!.uid,
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setState(() {
                      _infoText = authError
                          .loginErrorMsg((e as FirebaseAuthException).code);
                    });
                  }
                },
                child: Text(
                  'ログイン',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            TextButton(
              child: Text('上記メールアドレスにパスワード再設定メールを送信'),
              onPressed: () => _auth.sendPasswordResetEmail(email: _loginEmail),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ButtonTheme(
              minWidth: 350.0,
              child: ElevatedButton(
                child: Text(
                  'アカウントを作成する',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (BuildContext context) => Registration(camera: widget.camera, userId: _auth.currentUser?.uid ?? ""),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
