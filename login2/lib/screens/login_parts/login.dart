import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import '../../authentication_error.dart'; 
import '../../registration.dart';
import '../../email_check.dart';
import '../../home.dart';

class Login extends StatefulWidget {
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

      if (_user?.emailVerified ?? false) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Home(
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
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        String errorCode = (e as FirebaseAuthException).code;
        String errorMessage = e.message ?? "No message available";
        print("Error Code: $errorCode");
        print("Error Message: $errorMessage");
        _infoText = authError.loginErrorMsg(errorCode);
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: _loginEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('パスワード再設定メールが送信されました。'),
        ),
      );
    } catch (e) {
      setState(() {
        _infoText = authError.loginErrorMsg((e as FirebaseAuthException).code);
      });
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
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0), // 角丸にする
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue, width: 2.0), //フォーカス時の色
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.grey, width: 1.0), //通常時の色と幅
                  ),
                  labelStyle: TextStyle(
                    color: Colors.blue,
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
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
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
                  backgroundColor: Colors.blue, //ボタンの背景色
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
                      builder: (BuildContext context) => Registration(),
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
