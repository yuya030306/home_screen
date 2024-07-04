import 'package:flutter/material.dart';
import 'goals.dart'; // 目標トラッカー画面をインポート
import 'graph.dart'; // グラフ画面をインポート

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム画面'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalsScreen()),
                );
              },
              child: Text('目標トラッカー画面'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          GraphScreen(selectedGoal: '筋トレ')), // デフォルトの目標を設定
                );
              },
              child: Text('グラフ画面'),
            ),
          ],
        ),
      ),
    );
  }
}
