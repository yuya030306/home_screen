import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../theme.dart';

class SetGoalValueScreen extends StatefulWidget {
  final String? selectedPreset;
  final String? selectedUnit;

  SetGoalValueScreen({this.selectedPreset, this.selectedUnit});

  @override
  _SetGoalValueScreenState createState() => _SetGoalValueScreenState();
}

class _SetGoalValueScreenState extends State<SetGoalValueScreen> {
  final TextEditingController _valueController = TextEditingController();
  TimeOfDay? _selectedTime = TimeOfDay.now();

  void _addGoal() {
    if (widget.selectedPreset != null && widget.selectedUnit != null && _valueController.text.isNotEmpty && _selectedTime != null) {
      final DateTime now = DateTime.now();
      final DateTime deadline = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);

      if (deadline.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('締切時間は現在時刻より後に設定してください')),
        );
        return;
      }

      FirebaseFirestore.instance.collection('goals').add({
        'goal': widget.selectedPreset,
        'unit': widget.selectedUnit,
        'value': _valueController.text,
        'deadline': deadline,
        'userId': FirebaseAuth.instance.currentUser?.uid,
      }).then((documentReference) {
        scheduleNotification(documentReference.id, widget.selectedPreset!, deadline);
      });

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('すべてのフィールドを入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('目標値と締切を設定'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目標：${widget.selectedPreset}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  '単位： ${widget.selectedUnit}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: '目標値',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                Text(
                  '締切時間',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 200,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(hours: _selectedTime!.hour, minutes: _selectedTime!.minute),
                    onTimerDurationChanged: (Duration duration) {
                      setState(() {
                        _selectedTime = TimeOfDay(hour: duration.inHours, minute: duration.inMinutes % 60);
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _addGoal,
                    child: const Text('この内容で追加'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void scheduleNotification(String goalId, String goal, DateTime scheduledTime) async {
    var androidDetails = const AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    var generalNotificationDetails = NotificationDetails(android: androidDetails);

    print('Scheduled time: $scheduledTime');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Goal Reminder',
      'Time to achieve your goal: $goal',
      tz.TZDateTime.from(scheduledTime, tz.local),
      generalNotificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
