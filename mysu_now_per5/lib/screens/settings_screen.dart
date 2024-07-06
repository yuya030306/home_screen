import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'profile_screen.dart';
import 'friends_list_screen.dart';
import 'login.dart';
import 'friend_request_screen.dart';

class SettingsScreen extends StatelessWidget {
  final CameraDescription camera;
  final String userId;

  SettingsScreen({required this.camera, required this.userId});

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
                            MaterialPageRoute(builder: (context) => Login(camera: camera)),
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
                  MaterialPageRoute(builder: (context) => FriendsListScreen(userId: userId)),
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
