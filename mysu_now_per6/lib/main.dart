import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'screens/registration.dart';
import 'screens/home_screen.dart';
import 'screens/goals/dashboard_screen2.dart';
import 'screens/login.dart';
import 'screens/alarm_setting_screen.dart';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'screens/alarm_manager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late CameraDescription camera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AndroidAlarmManager.initialize();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

  await initializeNotifications();
  await requestNotificationPermission();
  await requestExactAlarmPermission();
  await disableBatteryOptimizations();

  final cameras = await availableCameras();
  camera = cameras.first;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  runApp(MyApp(camera: camera, auth: _auth));
  Workmanager().initialize(callbackDispatcher);
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  final FirebaseAuth auth;

  MyApp({required this.camera, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlarmManager>(
      create: (_) => AlarmManager(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Flutter Demo',
        theme: ThemeData.light(),
        home: Login(camera: camera),
        routes: {
          '/alarm': (context) => AlarmPage(
            camera: camera,
            userId: 'user_id',
          ),
          '/home': (context) => HomeScreen(
            camera: camera,
            userId: 'user_id',
            auth: auth,
          ),
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
    data: 'package:com.example.login',
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
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description:
    'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void onDidReceiveNotificationResponse(NotificationResponse response) {
  if (response.payload != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DashboardScreen2(camera: camera),
      ),
    );
  }
}
