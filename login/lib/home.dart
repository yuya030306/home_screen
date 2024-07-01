import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatelessWidget {
  final String userId;
  final FirebaseAuth auth;

  Home({required this.userId, required this.auth});

  @override
  Widget build(BuildContext context) {
    const List<String> _popmenuList = ["テスト", "ログアウト"];

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.home),
        title: Text('ログイン後の画面'),
        backgroundColor: Colors.black87,
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.menu),
            onSelected: (String s) {
              if (s == 'ログアウト') {
                auth.signOut();
                Navigator.of(context).pushNamed("/login");
              }
            },
            itemBuilder: (BuildContext context) {
              return _popmenuList.map((String s) {
                return PopupMenuItem(
                  child: Text(s),
                  value: s,
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ようこそ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(userId),
          ],
        ),
      ),
    );
  }
}
