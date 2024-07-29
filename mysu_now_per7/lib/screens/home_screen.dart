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
import 'goals/dashboard_screen.dart';
import 'goals/goal_card.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;
  final FirebaseAuth auth;

  HomeScreen({required this.camera, required this.userId, required this.auth});

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
    _scheduleDailyReset();
  }

  Future<void> _loadAlarmTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmTimeString = prefs.getString('alarmTimeString') ?? '00:00';
    });
  }

  void _scheduleDailyReset() {
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day + 1);
    var duration = midnight.difference(now);
    Future.delayed(duration, () {
      setState(() {});
      _scheduleDailyReset();
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
        return GraphScreen(
            selectedGoal: '', camera: widget.camera, userId: widget.userId);
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
      backgroundColor: Colors.orange[50],
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: _getScreen(_currentIndex),
      ),
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
              selectedColor: Colors.orange,
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
    var now = DateTime.now();
    var midnight = DateTime(now.year, now.month, now.day, 0, 0, 0);
    if (now.isAfter(midnight)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AlarmPage(camera: camera, userId: userId)),
                  ).then((_) {
                    reloadAlarmTime();
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

                    final goals = snapshot.data!.docs;

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
                        Map<String, dynamic> goalData = goal.data() as Map<String, dynamic>;
                        final isAchieved = goalData['isAchieved'] ?? false;
                        DateTime deadline = (goal['deadline'] as Timestamp).toDate();
                        bool isPastDeadline = deadline.isBefore(DateTime.now());
                        Color cardColor = isPastDeadline ? Colors.grey.shade300 : Colors.white;
                        cardColor = isAchieved ? Colors.green.shade100 : cardColor;

                        return Card(
                          color: cardColor,
                          child: ListTile(
                            title: Text(goal['goal']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${goal['value']} ${goal['unit']}'),
                                Text('締切: ${DateFormat('kk:mm').format(deadline)}まで'),
                              ],
                            ),
                            onTap: isAchieved ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecordGoalsScreen(
                                    camera: camera,
                                    userId: userId,
                                    goal: goal,
                                    isPastDeadline: isPastDeadline,
                                  ),
                                ),
                              );
                            },
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
                            builder: (context) => DashboardScreen(
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
    return Center(
      child: Text(
        '今日の目標はありません',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    paint.color = Colors.orange.shade200;

    path.reset();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
