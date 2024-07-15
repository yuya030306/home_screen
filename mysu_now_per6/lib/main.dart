import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'screens/registration.dart';
import 'screens/home_screen.dart';
import 'screens/login.dart';
import 'screens/alarm_setting_screen.dart';
import 'screens/alarm_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'screens/firebase_options.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/record_goals.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'screens/goals/dashboard_screen2.dart';

// グローバル変数として定義
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late CameraDescription camera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AndroidAlarmManager.initialize();

  // タイムゾーンの初期化
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

  // 通知の初期化処理
  await initializeNotifications();

  // 通知パーミッションのリクエスト
  await requestNotificationPermission();

  // 正確なアラームのパーミッションのリクエスト
  await requestExactAlarmPermission();

  // バッテリー最適化の無効化をリクエスト
  await disableBatteryOptimizations();

  final cameras = await availableCameras();
  camera = cameras.first;

  runApp(MyApp(camera: camera));
  Workmanager().initialize(callbackDispatcher);
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmManager(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Flutter Demo',
        theme: ThemeData.light(),
        home: Login(camera: camera),
        routes: {
          '/alarm': (context) => AlarmPage(camera: camera, userId: 'user_id'),
          '/home': (context) => HomeScreen(camera: camera, userId: 'user_id'),
          '/login': (context) => Login(camera: camera),
        },
      ),
    );
  }
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
    data: 'package:com.example.login', // あなたのアプリのパッケージ名に置き換えてください
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

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

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
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void onDidReceiveNotificationResponse(NotificationResponse response) {
  // 通知を選択した際の処理
  if (response.payload != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DashboardScreen2(camera: camera, userId: 'user_id'),
      ),
    );
  }
}