import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'alarm_manager.dart';
import 'goals/dashboard_screen.dart';
import 'package:camera/camera.dart';

class AlarmPage extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final CameraDescription camera;
  final String userId;

  AlarmPage({required this.camera, required this.userId});

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
        backgroundColor: Colors.orange,
      ),
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _alarmTimeString ?? 'アラームをセットしてください',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.black54,
                      fontFamily: 'Digital-7', // デジタル時計風フォント
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    textStyle: TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _alarmTimeString == null ? 'アラームをセット' : 'アラームを編集',
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final alarmManager =
                        Provider.of<AlarmManager>(context, listen: false);
                    alarmManager.stopAlarm();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardScreen(camera: widget.camera, userId: widget.userId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    textStyle: TextStyle(fontSize: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('アラームを停止'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    TimeOfDay initialTime = _selectedTime ?? TimeOfDay(hour: 0, minute: 0);
    if (alarmManager.alarmTimeString != null) {
      final alarmTime =
          DateFormat('a h:mm').parse(alarmManager.alarmTimeString!);
      initialTime = TimeOfDay(hour: alarmTime.hour, minute: alarmTime.minute);
    }

    final hourController =
        FixedExtentScrollController(initialItem: initialTime.hour);
    final minuteController =
        FixedExtentScrollController(initialItem: initialTime.minute);

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
                              controller: hourController,
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
                              controller: minuteController,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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
    final format = DateFormat('a h:mm'); // AM/PMの形式
    return format
        .format(dt)
        .replaceFirst(' ', ' ')
        .toUpperCase(); // AM/PM表記のカスタマイズ
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    paint.color = Colors.orange.shade200;

    path.reset();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.6, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
