import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'screens/registration.dart';
import 'screens/home_screen.dart';
import 'screens/login.dart';
import 'screens/alarm_setting_screen.dart';
import 'screens/alarm_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmManager(),
      child: MaterialApp(
        navigatorKey: AlarmPage.navigatorKey,
        title: 'Flutter Demo',
        theme: ThemeData.light(),
        home: Login(camera: camera),
        routes: {
          '/alarm': (context) => AlarmPage(),
          '/home': (context) => HomeScreen(camera: camera, userId: 'user_id'),
          '/login': (context) => Login(camera: camera),
        },
      ),
    );
  }
}
