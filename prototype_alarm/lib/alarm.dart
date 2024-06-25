import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  TimeOfDay? _selectedTime;
  String? _alarmTimeString;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アラーム画面'),
        actions: [
          IconButton(
            icon: Icon(Icons.show_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/graph');
            },
          ),
        ],
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
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _alarmTimeString = _formatTime(picked);
      });
      _setAlarm(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // "6:00 AM" or "18:00"
    return format.format(dt);
  }

  void _setAlarm(TimeOfDay time) {
    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (alarmTime.isBefore(now)) {
      // If the alarm time is earlier than the current time, set it for the next day
      alarmTime = alarmTime.add(Duration(days: 1));
    }

    final duration = alarmTime.difference(now);

    _timer?.cancel(); // Cancel any previous timer
    _timer = Timer(duration, _triggerAlarm);
  }

  void _triggerAlarm() {
    // Navigate to graph page
    Navigator.pushNamed(context, '/graph').then((_) {
      // Show the alarm dialog after navigating to the graph page
      _showAlarmDialog();
    });
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alarm"),
          content: Text("It's time!"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
