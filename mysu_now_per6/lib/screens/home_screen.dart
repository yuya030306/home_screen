import 'package:flutter/material.dart';
import 'alarm_setting_screen.dart';
import 'record_goals.dart';
import 'ranking_screen.dart';
import 'calendar_screen.dart';
import 'graph.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'goals/dashboard_screen2.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;

  HomeScreen({required this.camera, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _alarmTimeString = '00:00';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAlarmTime();
  }

  Future<void> _loadAlarmTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmTimeString = prefs.getString('alarmTimeString') ?? '00:00';
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return HomeContent(
          alarmTimeString: _alarmTimeString,
          userId: widget.userId,
          camera: widget.camera,
          reloadAlarmTime: _loadAlarmTime,
        );
      case 1:
        return CalendarScreen(camera: widget.camera, userId: widget.userId);
      case 2:
        return GraphScreen(selectedGoal: '', camera: widget.camera, userId: widget.userId);
      case 3:
        return SettingsScreen(camera: widget.camera, userId: widget.userId);
      default:
        return HomeContent(
          alarmTimeString: _alarmTimeString,
          userId: widget.userId,
          camera: widget.camera,
          reloadAlarmTime: _loadAlarmTime,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: _getScreen(_currentIndex), // 現在のインデックスに基づいて表示する画面を設定
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
            ),
          ],
        ),
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            SalomonBottomBarItem(
              icon: Icon(Icons.home),
              title: Text("ホーム"),
              selectedColor: Colors.blue,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.calendar_today),
              title: Text("カレンダー"),
              selectedColor: Colors.red,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.show_chart),
              title: Text("グラフ"),
              selectedColor: Colors.green,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.settings),
              title: Text("設定"),
              selectedColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final String alarmTimeString;
  final String userId;
  final CameraDescription camera;
  final Function reloadAlarmTime;

  HomeContent({
    required this.alarmTimeString,
    required this.userId,
    required this.camera,
    required this.reloadAlarmTime,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Text(
              '', // ここにタイトルを入力
              style: TextStyle(fontSize: 30),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlarmPage(camera: camera, userId: userId)),
                ).then((_) {
                  reloadAlarmTime(); // アラームページから戻ってきた時にアラーム時刻を再読み込み
                });
              },
              icon: Icon(Icons.alarm, size: 20),
              label: Text('アラーム設定'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 50),
              ),
            ),
            SizedBox(height: 20),
            Text(
              alarmTimeString,
              style: TextStyle(fontSize: 36),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .where('userId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final goals = snapshot.data!.docs.where((goal) {
                    final deadline = (goal['deadline'] as Timestamp).toDate();
                    return deadline.isAfter(DateTime.now());
                  }).toList();

                  if (goals.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      child: Text('目標がありません'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      var goal = goals[index];
                      return Card(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: ListTile(
                            title: Text(goal['goal']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${goal['value']} ${goal['unit']}'),
                                Text(
                                  '締切: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((goal['deadline'] as Timestamp).toDate())}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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
                  icon: Icon(Icons.leaderboard, size: 20),
                  label: Text('ランキング'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen2(
                              camera: camera, userId: userId)),
                    );
                  },
                  icon: Icon(Icons.edit, size: 20),
                  label: Text('目標入力ボタン'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}