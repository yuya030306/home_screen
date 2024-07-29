import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'alarm_manager.dart';
import 'goals/dashboard_screen.dart';
import 'package:camera/camera.dart';

class AlarmPage extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  final CameraDescription camera;
  final String userId;

  AlarmPage({required this.camera, required this.userId});

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  TimeOfDay? _selectedTime;
  String? _alarmTimeString;
  String? _selectedSound; // 選択されたアラーム音
  int _selectedHour = 0;
  int _selectedMinute = 0;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadInitialTime();

    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    alarmManager.addListener(_onAlarmTriggered);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alarmManager = Provider.of<AlarmManager>(context);
    if (alarmManager.isAlarmRinging && !_isDialogOpen) {
      _isDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAlarmDialog();
      });
    }
  }

  @override
  void dispose() {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    alarmManager.removeListener(_onAlarmTriggered);
    super.dispose();
  }

  void _loadInitialTime() {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    setState(() {
      _alarmTimeString = alarmManager.alarmTimeString;
      _selectedSound = alarmManager.alarmSound; // アラーム音をロード
      if (_alarmTimeString != null) {
        final alarmTime = DateFormat('a h:mm').parse(_alarmTimeString!);
        _selectedTime =
            TimeOfDay(hour: alarmTime.hour, minute: alarmTime.minute);
        _selectedHour = _selectedTime!.hour;
        _selectedMinute = _selectedTime!.minute;
      }
    });
  }

  void _onAlarmTriggered() {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    if (alarmManager.isAlarmRinging && !_isDialogOpen) {
      _isDialogOpen = true;
      showAlarmDialog();
    } else if (!alarmManager.isAlarmRinging && _isDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogOpen = false;
    }
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
              children: <Widget>[
                Spacer(flex: 1), // 上半分のスペースを確保
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 300, // ボタンの幅に合わせる
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20), // パディングを調整
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.orange.shade200, width: 3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _alarmTimeString ?? 'アラームをセットしてください',
                      style: TextStyle(
                        fontSize: 28, // フォントサイズを大きく
                        color: Colors.black54,
                        fontFamily: 'Digital-7', // デジタル時計風フォント
                        letterSpacing: 3.0,
                      ),
                      textAlign: TextAlign.center, // テキストを中央揃え
                    ),
                  ),
                ),
                Spacer(flex: 2), // アラーム時刻とボタンの間にスペースを追加
                Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _pickTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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
                      onPressed: _changeAlarmSound,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('アラーム音を変更'),
                    ),
                    SizedBox(height: 20),
                    if (_alarmTimeString != null) // アラームが設定されている場合のみ表示
                      ElevatedButton(
                        onPressed: _deleteAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          textStyle: TextStyle(fontSize: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text('アラームを削除'),
                      ),
                    if (_selectedSound != null) // アラーム音が設定されている場合のみ表示
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          '選択されたアラーム音: アラーム音$_selectedSound',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                  ],
                ),
                Spacer(flex: 1), // 下部にスペースを確保
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
                    setState(() {
                      _selectedTime = TimeOfDay(
                          hour: _selectedHour, minute: _selectedMinute);
                      _alarmTimeString = _formatTime(_selectedTime!);
                    });
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

  void _deleteAlarm() {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    alarmManager.resetAlarm();
    setState(() {
      _alarmTimeString = null;
    });
  }

  void _changeAlarmSound() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('アラーム音を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('アラーム音A'),
                onTap: () => _selectAlarmSound('A'),
              ),
              ListTile(
                title: Text('アラーム音B'),
                onTap: () => _selectAlarmSound('B'),
              ),
              ListTile(
                title: Text('アラーム音C'),
                onTap: () => _selectAlarmSound('C'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectAlarmSound(String sound) {
    final alarmManager = Provider.of<AlarmManager>(context, listen: false);
    alarmManager.setAlarmSound(sound);
    setState(() {
      _selectedSound = sound;
    });
    Navigator.of(context).pop();
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

  // アラームが鳴ったときにダイアログを表示するメソッド
  void showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ダイアログ外をタップしても閉じないようにする
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('アラーム'),
          content: Text(
            'おはようございます！\n今日の目標を入力しましょう！',
            textAlign: TextAlign.center, // テキストを中央に揃える
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                final alarmManager =
                    Provider.of<AlarmManager>(context, listen: false);
                alarmManager.stopAlarm();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(
                      camera: widget.camera,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('目標を入力'),
            ),
          ],
        );
      },
    );
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
