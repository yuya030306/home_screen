import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart'; // CameraDescription をインポート
import 'authentication_error.dart';
import 'email_check.dart';
import 'home_screen.dart'; // HomeScreen をインポート

class Registration extends StatefulWidget {
  final CameraDescription camera;
  final String userId;

  Registration({required this.camera, required this.userId});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _auth = FirebaseAuth.instance;
  UserCredential? _result;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _newEmail = "";
  String _newPassword = "";
  String _newUsername = "";
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
                decoration: InputDecoration(labelText: "ユーザーネーム"),
                onChanged: (String value) {
                  _newUsername = value;
                },
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
                      // ユーザ名の重複チェック
                      final QuerySnapshot result = await _firestore
                          .collection('users')
                          .where('username', isEqualTo: _newUsername)
                          .get();
                      final List<DocumentSnapshot> documents = result.docs;
                      if (documents.isNotEmpty) {
                        setState(() {
                          _infoText = 'このユーザ名はすでに登録されています。';
                        });
                        return;
                      }

                      _result = await _auth.createUserWithEmailAndPassword(
                        email: _newEmail,
                        password: _newPassword,
                      );

                      User? user = _result?.user;

                      if (user != null) {
                        await _firestore.collection('users').doc(user.uid).set({
                          'username': _newUsername,
                          'email': _newEmail,
                        });

                        try {
                          await user.sendEmailVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('確認メールが送信されました')),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmailCheck(
                                email: _newEmail,
                                pswd: _newPassword,
                                from: 1,
                                camera: widget.camera,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        } catch (e) {
                          setState(() {
                            _infoText = '確認メールの送信に失敗しました: $e';
                          });
                        }
                      }
                    } catch (e) {
                      setState(() {
                        _infoText = authError.registerErrorMsg(
                            (e as FirebaseAuthException).code);
                      });
                    }
                  } else {
                    setState(() {
                      _infoText = 'パスワードは6文字以上です。';
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
