import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'authentication_error.dart';
import 'registration.dart';
import 'email_check.dart';
import 'home_screen.dart';
import 'package:provider/provider.dart';
import 'alarm_manager.dart';

class Login extends StatefulWidget {
  final CameraDescription camera;

  Login({required this.camera});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // Firestoreインスタンスを追加
  UserCredential? _result;
  User? _user;

  String _loginEmail = "";
  String _loginPassword = "";
  String _infoText = "";

  final authError = AuthenticationError(); // インスタンスの作成

  Future<void> signIn() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _infoText = "インターネット接続がありません。接続を確認してください。";
      });
      return;
    }

    try {
      _result = await _auth.signInWithEmailAndPassword(
        email: _loginEmail,
        password: _loginPassword,
      );
      _user = _result?.user;

      if (_user?.emailVerified ?? true) {
        final alarmManager = Provider.of<AlarmManager>(context, listen: false);
        await alarmManager.resetAlarm();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              camera: widget.camera,
              userId: _user!.uid,
              auth: _auth,
            ),
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
              username: "", // EmailCheck画面でFirestoreに保存するためのユーザー名を追加します。
            ),
          ),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        setState(() {
          _infoText = authError.loginErrorMsg(e.code);
        });
      } else {
        setState(() {
          _infoText = "不明なエラーが発生しました。";
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      // Firestoreでメールアドレスの存在を確認
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _loginEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _infoText = 'そのメールアドレスは登録されていません。';
        });
        return;
      }

      await _auth.sendPasswordResetEmail(email: _loginEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('パスワード再設定メールが送信されました。'),
        ),
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        setState(() {
          _infoText = authError.loginErrorMsg(e.code);
        });
      } else {
        setState(() {
          _infoText = "不明なエラーが発生しました。";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image(
              image: AssetImage('images/sample.jpg'),
              width: 110.0,
              height: 150.0,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "メールアドレス",
                  hintText: "例: user@example.com",
                  prefixIcon: Icon(Icons.email), // アイコンを追加
                  fillColor: Colors.orange[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0), // 角丸にする
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.orange, width: 2.0), //フォーカス時の色
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey, width: 1.0), //通常時の色と幅
                  ),
                  labelStyle: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onChanged: (String value) {
                  _loginEmail = value;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 10, 25.0, 0.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "パスワード（6～20文字）",
                  hintText: "パスワードを入力してください",
                  prefixIcon: Icon(Icons.lock),
                  fillColor: Colors.orange[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
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
                  _loginPassword = value;
                },
              ),
            ),
            Padding(
              // エラーメッセージ
              padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
              child: Text(
                _infoText,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.0,
                ),
              ),
            ),
            SizedBox(
              //固定サイズのボックスを作成
              width: 350.0,
              height: 50,
              child: ElevatedButton(
                //押せるボタンを作成
                onPressed: signIn,
                child: Text('ログイン',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, //テキストを太字
                      fontSize: 18,
                    )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, //ボタンの背景色
                  foregroundColor: Colors.white, //テキスト色
                  shape: RoundedRectangleBorder(
                    //shape:ボタンの形状,RoundedRectangleBorder:角が丸い四角形に設定します。
                    borderRadius: BorderRadius.circular(10), // 角の丸みを10ピクセルに設定し
                  ),
                ),
              ),
            ),
            TextButton(
              child: Text('上記のメールアドレスにパスワード再設定メールを送信'),
              onPressed: _sendPasswordResetEmail,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 370.0,
              height: 50,
              child: ElevatedButton(
                child: Text(
                  'アカウントを作成する',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[50],
                  foregroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (BuildContext context) => Registration(
                          camera: widget.camera,
                          userId: _auth.currentUser?.uid ?? ""),
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
