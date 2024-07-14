import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'graph.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'package:camera/camera.dart'; // camera パッケージをインポート

class BottomNavBar extends StatelessWidget {
  final CameraDescription camera;
  final String userId;

  BottomNavBar({required this.camera, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 4.0,
      color: Colors.orange, // タスクバーの色を設定
      child: Container(
        height: 40.0, // タスクバーの高さを調整
        padding: EdgeInsets.symmetric(horizontal: 10.0), // タスクバーの幅を調整
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(camera: camera, userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.calendar_today, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(camera: camera, userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.show_chart, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraphScreen(camera: camera, userId: userId, selectedGoal: ''),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(camera: camera, userId: userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
