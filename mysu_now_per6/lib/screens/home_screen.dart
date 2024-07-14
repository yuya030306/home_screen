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

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;

  HomeScreen({required this.camera, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _alarmTimeString = '00:00';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50], // 画面全体の背景色を設定
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0), // 画面全体のボタンなどを下に移動
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40), // タイトル欄を作成
              Text(
                '', // ここにタイトルを入力
                style: TextStyle(fontSize: 30),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlarmPage()),
                  ).then((_) {
                    _loadAlarmTime(); // アラームページから戻ってきた時にアラーム時刻を再読み込み
                  });
                },
                icon: Icon(Icons.alarm, size: 20),
                label: Text('アラーム設定'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(150, 50), // ボタンのサイズを設定
                ),
              ),
              SizedBox(height: 20),
              Text(
                _alarmTimeString,
                style: TextStyle(fontSize: 36),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('goals')
                      .where('userId', isEqualTo: widget.userId)
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
                        padding: const EdgeInsets.only(bottom: 80.0), // 「目標がありません」の表示を下に移動
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
                            width: MediaQuery.of(context).size.width * 0.8, // 幅を減らす
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
                        MaterialPageRoute(
                            builder: (context) => RankingScreen()), // ランキング画面への遷移
                      );
                    },
                    icon: Icon(Icons.leaderboard, size: 20),
                    label: Text('ランキング'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 50), // ボタンのサイズを設定
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RecordGoalsScreen(
                                camera: widget.camera, userId: widget.userId)),
                      );
                    },
                    icon: Icon(Icons.edit, size: 20),
                    label: Text('目標入力ボタン'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 50), // ボタンのサイズを設定
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 1.0,
        color: Colors.orange[300], // タスクバーの色を設定
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.0), // タスクバーの幅を調整
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home, size: 30), // アイコンのサイズを少し小さく
                onPressed: () {
                  // ホーム画面へのナビゲーション
                },
              ),
              IconButton(
                icon: Icon(Icons.calendar_today, size: 30), // アイコンのサイズを少し小さく
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalendarScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.show_chart, size: 30), // アイコンのサイズを少し小さく
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GraphScreen(selectedGoal: '')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.settings, size: 30), // アイコンのサイズを少し小さく
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                            camera: widget.camera, userId: widget.userId)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
