import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class SetGoalValueScreen extends StatefulWidget {
  final String? selectedPreset;
  final String? selectedUnit;

  SetGoalValueScreen({this.selectedPreset, this.selectedUnit});

  @override
  _SetGoalValueScreenState createState() => _SetGoalValueScreenState();
}

class _SetGoalValueScreenState extends State<SetGoalValueScreen> {
  final TextEditingController _valueController = TextEditingController();
  TimeOfDay? _selectedTime = TimeOfDay.now(); // 初期値を現在の時刻に設定

  void _addGoal() {
    if (widget.selectedPreset != null && widget.selectedUnit != null && _valueController.text.isNotEmpty && _selectedTime != null) {
      final DateTime now = DateTime.now();
      final DateTime deadline = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);

      FirebaseFirestore.instance.collection('goals').add({
        'goal': widget.selectedPreset,
        'unit': widget.selectedUnit,
        'value': _valueController.text,
        'deadline': deadline,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目標値と締切を設定'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '目標：${widget.selectedPreset ?? "なし"}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '単位： ${widget.selectedUnit ?? "なし"}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: '目標値',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              Text(
                '締切時間',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 200, // 固定の高さを設定してオーバーフローを防ぐ
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: Duration(hours: _selectedTime!.hour, minutes: _selectedTime!.minute),
                  onTimerDurationChanged: (Duration duration) {
                    setState(() {
                      _selectedTime = TimeOfDay(hour: duration.inHours, minute: duration.inMinutes % 60);
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _addGoal,
                  child: const Text('この内容で追加'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
