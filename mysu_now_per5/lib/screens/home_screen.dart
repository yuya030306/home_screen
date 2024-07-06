import 'package:flutter/material.dart';
import 'alarm_setting_screen.dart';
import 'goals.dart';
import 'ranking_screen.dart';
import 'time_setting_screen.dart';
import 'calendar_screen.dart';
import 'graph.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;

  HomeScreen({required this.camera});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String goal = '目標を表示';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlarmPage()),
                );
              },
              icon: Icon(Icons.alarm, size: 40),
              label: Text('アラーム設定'),
            ),
            SizedBox(height: 20),
            Text(
              '00:00',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  goal = '目標表示ボタン';
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 100),
              ),
              child: Text(
                goal,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalsScreen(camera: widget.camera)),
                );
              },
              icon: Icon(Icons.edit, size: 32),
              label: Text('目標入力ボタン'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RankingScreen()), // ランキング画面への遷移
                    );
                  },
                  icon: Icon(Icons.leaderboard, size: 32),
                  label: Text('ランキング'),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TimeSettingScreen()),
                    );
                  },
                  icon: Icon(Icons.access_time, size: 32),
                  label: Text('時刻設定'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 45),
              onPressed: () {
                // ホーム画面へのナビゲーション
              },
            ),
            IconButton(
              icon: Icon(Icons.calendar_today, size: 45),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalendarScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.show_chart, size: 45),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GraphScreen(selectedGoal: '')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 45),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen(camera: widget.camera)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
