import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'alarm_setting_screen.dart';

class AlarmManager extends ChangeNotifier {
  TimeOfDay? _selectedTime;
  String? _alarmTimeString;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmRinging = false;

  AlarmManager() {
    _loadAlarmTime();
  }

  Future<void> _loadAlarmTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedTime = TimeOfDay(
      hour: prefs.getInt('selectedHour') ?? 0,
      minute: prefs.getInt('selectedMinute') ?? 0,
    );
    _alarmTimeString = prefs.getString('alarmTimeString');
    if (_alarmTimeString != null) {
      _startAlarmTimer();
    }
  }

  Future<void> _saveAlarmTime(
      int hour, int minute, String alarmTimeString) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedHour', hour);
    await prefs.setInt('selectedMinute', minute);
    await prefs.setString('alarmTimeString', alarmTimeString);
    _selectedTime = TimeOfDay(hour: hour, minute: minute);
    _alarmTimeString = alarmTimeString;
    _startAlarmTimer();
  }

  void _startAlarmTimer() {
    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(Duration(days: 1));
    }

    final duration = alarmTime.difference(now);

    _timer?.cancel();
    _timer = Timer(duration, () {
      _playAlarm();
      _isAlarmRinging = true;
      notifyListeners();
    });
  }

  void _playAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('alarm_sound.mp3'));
  }

  void stopAlarm() {
    _audioPlayer.stop();
    _isAlarmRinging = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String? get alarmTimeString => _alarmTimeString;
  bool get isAlarmRinging => _isAlarmRinging;

  void setAlarm(int hour, int minute, String alarmTimeString) {
    _saveAlarmTime(hour, minute, alarmTimeString);
    notifyListeners();
  }

  Future<void> resetAlarm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedHour');
    await prefs.remove('selectedMinute');
    await prefs.remove('alarmTimeString');
    _selectedTime = null;
    _alarmTimeString = null;
    _timer?.cancel();
    notifyListeners();
  }
}
