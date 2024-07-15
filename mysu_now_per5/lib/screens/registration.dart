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
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 50.0, top: 130.0), // 画像の下に余白を追加
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
                  prefixIcon: Icon(Icons.person), // アイコンを追加
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0), // 角丸にする
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue, width: 2.0), // フォーカス時の色
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey, width: 1.0), // 通常時の色と幅
                  ),
                  labelStyle: TextStyle(
                    color: Colors.blue,
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
                  prefixIcon: Icon(Icons.email), // アイコンを追加
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0), // 角丸にする
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue, width: 2.0), // フォーカス時の色
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey, width: 1.0), // 通常時の色と幅
                  ),
                  labelStyle: TextStyle(
                    color: Colors.blue,
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
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.blue,
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
                  if (_pswdOK) {
                    try {
                      // ユーザーネームの重複確認
                      final querySnapshot = await _firestore
                          .collection('users')
                          .where('username', isEqualTo: _newUsername)
                          .get();
                      if (querySnapshot.docs.isNotEmpty) {
                        setState(() {
                          _infoText = 'このユーザーネームは既に使用されています。';
                        });
                        return;
                      }

                      _result = await _auth.createUserWithEmailAndPassword(
                        email: _newEmail,
                        password: _newPassword,
                      );

                      _user = _result?.user;

                      if (_user != null) {
                        await _firestore
                            .collection('users')
                            .doc(_user!.uid)
                            .set({
                          'username': _newUsername,
                          'email': _newEmail,
                          'friends': [],
                          'friendRequests': [],
                        });

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
                            ),
                          ),
                        );
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
                child: Text(
                  '登録',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
          ],
        ),
      ),
    );
  }
}
