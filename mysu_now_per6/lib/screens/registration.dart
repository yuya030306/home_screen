import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'authentication_error.dart';
import 'email_check.dart';
import 'home_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  User? _user;
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('新規アカウントの作成'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 50.0, top: 50.0),
                  child: Image(
                    image: AssetImage('images/sample.jpg'),
                    width: 110.0,
                    height: 150.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 10.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "ユーザーネーム",
                      hintText: "例: username123",
                      prefixIcon: Icon(Icons.person),
                      fillColor: Colors.orange[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.orange, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: (String value) {
                      _newUsername = value;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 10.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "メールアドレス",
                      hintText: "例: user@example.com",
                      prefixIcon: Icon(Icons.email),
                      fillColor: Colors.orange[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.orange, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: (String value) {
                      _newEmail = value;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(25.0, 0, 25.0, 10.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "パスワード（6～20文字）",
                      hintText: "パスワードを入力してください",
                      prefixIcon: Icon(Icons.lock),
                      fillColor: Colors.orange[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.orange, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    obscureText: true,
                    maxLength: 20,
                    onChanged: (String value) {
                      if (value.length >= 6) {
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
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                SizedBox(
                  width: 350.0,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      var connectivityResult =
                          await (Connectivity().checkConnectivity());
                      if (connectivityResult == ConnectivityResult.none) {
                        setState(() {
                          _infoText = "インターネット接続がありません。接続を確認してください。";
                        });
                        return;
                      }
                      if (_newUsername.isEmpty) {
                        setState(() {
                          _infoText = 'ユーザ名を入力してください。';
                        });
                        return;
                      }
                      if (_newEmail.isEmpty) {
                        setState(() {
                          _infoText = 'メールアドレスを入力してください。';
                        });
                        return;
                      }
                      if (_pswdOK) {
                        // 非同期処理を含む関数を呼び出す
                        await _registerUser();
                      } else {
                        setState(() {
                          _infoText = 'パスワードは6文字以上です。';
                        });
                      }
                    },
                    child: Text(
                      '登録',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    try {
      // Firestoreに既存のユーザーを確認
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _newEmail)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _infoText = '既に登録済みのメールアドレスです。';
        });
        return;
      }

      // 認証用のユーザーを作成
      _result = await _auth.createUserWithEmailAndPassword(
        email: _newEmail,
        password: _newPassword,
      );

      _user = _result?.user;

      if (_user != null) {
        await _user?.sendEmailVerification();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailCheck(
              email: _newEmail,
              pswd: _newPassword,
              from: 1,
              camera: widget.camera,
              userId: widget.userId,
              username: _newUsername,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() async {
        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            // Firestoreに確認済みのメールアドレスをチェック
            final querySnapshot = await _firestore
                .collection('users')
                .where('email', isEqualTo: _newEmail)
                .get();
            if (querySnapshot.docs.isNotEmpty) {
              _infoText = '既に登録済みのメールアドレスです。';
            } else {
              _infoText = 'メール確認が完了していません。';
              // ここで再度メール確認画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailCheck(
                    email: _newEmail,
                    pswd: _newPassword,
                    from: 1,
                    camera: widget.camera,
                    userId: widget.userId,
                    username: _newUsername,
                  ),
                ),
              );
            }
          } else if (e.code == 'invalid-email') {
            _infoText = '正しいメールアドレスを入力してください。';
          } else if (e.code == 'network-request-failed') {
            _infoText = "インターネット接続がありません。接続を確認してください。";
          } else {
            _infoText = authError.registerErrorMsg(e.code);
          }
        } else {
          _infoText = "不明なエラーが発生しました。";
        }
      });
    }
  }
}
