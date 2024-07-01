import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'goal_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AndroidAlarmManager.initialize();
  runApp(GoalApp());
  Workmanager().initialize(callbackDispatcher);
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'deleteGoal') {
      String goalId = inputData!['goalId'];
      await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
    }
    return Future.value(true);
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void scheduleNotification(String goalId, String goal) async {
  var androidDetails = const AndroidNotificationDetails(
    'channelId',
    'channelName',
    channelDescription: 'channelDescription',
    importance: Importance.high,
  );
  var generalNotificationDetails =
  NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
      0, 'Goal Reminder', 'Time to achieve your goal: $goal', generalNotificationDetails,
      payload: goalId);
}

Future<void> deleteGoalCallback(int id, Map<String, dynamic> params) async {
  String goalId = params['goalId'];
  await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
  print('Goal $goalId deleted');
}
