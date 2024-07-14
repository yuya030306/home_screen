import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'firebase_options.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'goal_app.dart';
import 'record_goals.dart';  // 追加
import 'package:permission_handler/permission_handler.dart';  // パーミッションハンドラーの追加
import 'package:android_intent_plus/android_intent.dart';  // AndroidIntentパッケージの追加
import 'package:android_intent_plus/flag.dart';  // フラグのインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AndroidAlarmManager.initialize();

  // タイムゾーンの初期化
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));  // 必要に応じてタイムゾーンを設定

  // 通知の初期化処理
  await initializeNotifications();

  // 通知パーミッションのリクエスト
  await requestNotificationPermission();

  // 正確なアラームのパーミッションのリクエスト
  await requestExactAlarmPermission();

  // バッテリー最適化の無効化をリクエスト
  await disableBatteryOptimizations();

  runApp(GoalApp());
  Workmanager().initialize(callbackDispatcher);
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

Future<void> disableBatteryOptimizations() async {
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }

  const AndroidIntent intent = AndroidIntent(
    action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
    data: 'package:com.example.addgoals4.addgoals4', // あなたのアプリのパッケージ名に置き換えてください
    flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
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

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

  // 通知チャネルの設定
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // 通知チャネルのID
    'High Importance Notifications', // 通知チャネルの名前
    description: 'This channel is used for important notifications.', // 通知チャネルの説明
    importance: Importance.high,
  );

  // 通知チャネルの作成
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void onDidReceiveNotificationResponse(NotificationResponse response) {
  // 通知を選択した際の処理
  if (response.payload != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => RecordGoalsScreen(),
      ),
    );
  }
}

void scheduleNotification(String goalId, String goal, DateTime scheduledTime) async {
  var androidDetails = const AndroidNotificationDetails(
    'high_importance_channel', // 通知チャネルのID
    'High Importance Notifications', // 通知チャネルの名前
    channelDescription: 'This channel is used for important notifications.', // 通知チャネルの説明
    importance: Importance.high,
  );
  var generalNotificationDetails = NotificationDetails(android: androidDetails);

  print('Scheduled time: $scheduledTime'); // スケジュールされる時間を確認するためのデバッグ出力

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Goal Reminder',
    'Time to achieve your goal: $goal',
    tz.TZDateTime.from(scheduledTime, tz.local),  // 指定した日時に一度だけ通知を送信
    generalNotificationDetails,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
