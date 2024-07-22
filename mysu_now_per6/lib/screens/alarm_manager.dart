import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AlarmManager extends ChangeNotifier {
  TimeOfDay? _selectedTime;
  String? _alarmTimeString;
  String? _selectedSound; // アラーム音の追加
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmRinging = false;
  int _playCount = 0; // 再生回数をカウント

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
    _selectedSound = prefs.getString('selectedSound'); // アラーム音をロード
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

  Future<void> _saveAlarmSound(String sound) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSound', sound);
    _selectedSound = sound;
    notifyListeners();
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
    String alarmSound = 'alarm_sound_A.mp3'; // デフォルトのアラーム音
    if (_selectedSound != null) {
      alarmSound = 'alarm_sound_$_selectedSound.mp3'; // 選択されたアラーム音
    }
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.onPlayerComplete.listen((event) async {
      _playCount++;
      if (_playCount < 20) {
        await _audioPlayer.play(AssetSource(alarmSound));
      } else {
        stopAlarm();
      }
    });
    await _audioPlayer.play(AssetSource(alarmSound));
  }

  void stopAlarm() {
    _audioPlayer.stop();
    _isAlarmRinging = false;
    _playCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String? get alarmTimeString => _alarmTimeString;
  String? get alarmSound => _selectedSound; // アラーム音のgetter
  bool get isAlarmRinging => _isAlarmRinging;

  void setAlarm(int hour, int minute, String alarmTimeString) {
    _saveAlarmTime(hour, minute, alarmTimeString);
    notifyListeners();
  }

  void setAlarmSound(String sound) {
    _saveAlarmSound(sound);
    notifyListeners();
  }

  Future<void> resetAlarm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedHour');
    await prefs.remove('selectedMinute');
    await prefs.remove('alarmTimeString');
    await prefs.remove('selectedSound'); // アラーム音の削除
    _selectedTime = null;
    _alarmTimeString = null;
    _selectedSound = null; // アラーム音のリセット
    _timer?.cancel();
    notifyListeners();
  }
}
