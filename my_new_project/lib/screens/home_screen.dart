import 'package:flutter/material.dart';
import 'alarm_setting_screen.dart';
import 'goal_input_screen.dart';
import 'ranking_screen.dart';
import 'time_setting_screen.dart';
import 'calendar_screen.dart';
import 'chart_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
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
                  MaterialPageRoute(builder: (context) => AlarmSettingScreen()),
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
                  goal = '新しい目標を設定';
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
                  MaterialPageRoute(builder: (context) => GoalInputScreen()),
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
                      MaterialPageRoute(builder: (context) => RankingScreen()),
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
                  MaterialPageRoute(builder: (context) => ChartScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 45),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
