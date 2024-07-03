import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  TimeOfDay? _selectedTime;
  String? _alarmTimeString;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _selectedHour = 0;
  int _selectedMinute = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startAlarmTimer() {
    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedHour,
      _selectedMinute,
    );

    if (alarmTime.isBefore(now)) {
      // アラームが現在の時刻よりも前の場合、次の日に設定。
      alarmTime = alarmTime.add(Duration(days: 1));
    }

    final duration = alarmTime.difference(now);

    _timer?.cancel(); // 既存のタイマーをキャンセル

    _timer = Timer(duration, () {
      _playAlarm();
      _showAlarmDialog();
    });
  }

  void _playAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // ループ再生に設定
    await _audioPlayer.play(AssetSource('alarm_sound.mp3'));
  }

  void _stopAlarm() {
    _audioPlayer.stop();
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("アラーム"),
          content: Text("アラームが鳴っています！"),
          actions: [
            ElevatedButton(
              onPressed: () {
                _stopAlarm();
                Navigator.of(context).pop();
              },
              child: Text("アラームを止める"),
            ),
          ],
        );
      },
    );
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
              _alarmTimeString ?? 'アラームがセットされていません',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickTime,
              child: Text('アラームをセット'),
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
                        height: 150, // 明示的な高さを指定
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
                        height: 150, // 明示的な高さを指定
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
                    Navigator.of(context).pop();
                    _startAlarmTimer(); // アラームタイマーを開始
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
    final format = DateFormat.jm(); // 'jm' => '5:08 PM'
    return format.format(dt);
  }
}
