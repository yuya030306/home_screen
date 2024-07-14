import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart'; // CameraDescription をインポート
import 'profile_screen.dart';
import 'friends_screen.dart';
import 'login.dart'; // 修正: LoginScreen をインポート

class SettingsScreen extends StatelessWidget {
  final CameraDescription camera;

  SettingsScreen({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Text('プロフィール'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('ログアウト'),
                    content: Text('ログアウトしますか'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('いいえ'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => Login(camera: camera)), // 修正: Login に変更
                                (Route<dynamic> route) => false,
                          );
                        },
                        child: Text('はい'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('ログアウト'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FriendsScreen()),
                );
              },
              child: Text('フレンド追加確認'),
            ),
          ],
        ),
      ),
    );
  }
}
