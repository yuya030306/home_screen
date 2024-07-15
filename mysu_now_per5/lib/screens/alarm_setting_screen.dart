import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'alarm_manager.dart';
import 'goals/goal_screen.dart';  // GoalScreenをインポート

class AlarmPage extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  TimeOfDay? _selectedTime;
  String? _alarmTimeString;
  int _selectedHour = 0;
  int _selectedMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialTime();
  }

  void _loadInitialTime() {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    setState(() {
      _alarmTimeString = alarmManager.alarmTimeString;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アラーム画面'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _alarmTimeString ?? 'アラームをセットしてください',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickTime,
              child: Text(_alarmTimeString == null ? 'アラームをセット' : 'アラームを編集'),
            ),
            ElevatedButton(
              onPressed: () {
                final alarmManager = Provider.of<AlarmManager>(context, listen: false);
                alarmManager.stopAlarm();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalScreen()),
                );
              },
              child: Text('アラームを停止'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 250,
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                              diameterRatio: 1.5,
                              physics: FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedHour = index;
                                  _selectedTime = TimeOfDay(
                                      hour: _selectedHour,
                                      minute: _selectedMinute);
                                  _alarmTimeString =
                                      _formatTime(_selectedTime!);
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      '$index',
                                      style: TextStyle(
                                        fontSize: 24,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 24,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: Text(
                                '時',
                                style: TextStyle(
                                    fontSize: 24, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                              diameterRatio: 1.5,
                              physics: FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedMinute = index;
                                  _selectedTime = TimeOfDay(
                                      hour: _selectedHour,
                                      minute: _selectedMinute);
                                  _alarmTimeString =
                                      _formatTime(_selectedTime!);
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      '$index',
                                      style: TextStyle(
                                        fontSize: 24,
                                      ),
                                    ),
                                  );
                                },
                                childCount: 60,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: Text(
                                '分',
                                style: TextStyle(
                                    fontSize: 24, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final alarmManager =
                    Provider.of<AlarmManager>(context, listen: false);
                    alarmManager.setAlarm(
                        _selectedHour, _selectedMinute, _alarmTimeString!);
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }
}
