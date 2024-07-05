import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphScreen extends StatefulWidget {
  final String selectedGoal;

  GraphScreen({required this.selectedGoal});

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<_RecordData> _weeklyData = [];
  List<_RecordData> _monthlyData = [];
  String _selectedPeriod = '週';
  String _goalUnit = '';
  List<String> _goals = [];
  String _selectedGoal = '';
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.selectedGoal;
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    final firestore = FirebaseFirestore.instance;
    final goalsSnapshot = await firestore.collection('goals').get();
    List<String> goals = goalsSnapshot.docs.map((doc) => doc.id).toList();

    setState(() {
      _goals = goals;
      if (_goals.isNotEmpty) {
        _selectedGoal = _goals.contains(widget.selectedGoal)
            ? widget.selectedGoal
            : _goals.first;
        _updateGoalData();
      }
    });
  }

  Future<void> _updateGoalData() async {
    await _fetchGoalUnit();
    await _fetchWeeklyData();
    await _fetchMonthlyData();
  }

  Future<void> _fetchGoalUnit() async {
    final firestore = FirebaseFirestore.instance;
    final goalDoc =
        await firestore.collection('goals').doc(_selectedGoal).get();

    setState(() {
      _goalUnit = goalDoc.data()?['unit'] ?? '';
    });
  }

  Future<void> _fetchWeeklyData() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('records')
        .where('goal', isEqualTo: _selectedGoal)
        .orderBy('date')
        .get();

    List<_RecordData> records = snapshot.docs.map((doc) {
      return _RecordData(
        date: doc['date'] ?? '',
        value: double.tryParse(doc['value'] ?? '0') ?? 0,
      );
    }).toList();

    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: 6));

    Map<String, double> weeklyDataMap = Map.fromIterable(
      List.generate(7, (index) => startDate.add(Duration(days: index))),
      key: (date) => date.toString().split(' ')[0],
      value: (date) => 0.0,
    );

    for (var record in records) {
      if (weeklyDataMap.containsKey(record.date)) {
        weeklyDataMap[record.date] = record.value;
      }
    }

    setState(() {
      _weeklyData = weeklyDataMap.entries
          .map((entry) => _RecordData(date: entry.key, value: entry.value))
          .toList();
    });
  }

  Future<void> _fetchMonthlyData() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('records')
        .where('goal', isEqualTo: _selectedGoal)
        .orderBy('date')
        .get();

    List<_RecordData> records = snapshot.docs.map((doc) {
      return _RecordData(
        date: doc['date'] ?? '',
        value: double.tryParse(doc['value'] ?? '0') ?? 0,
      );
    }).toList();

    DateTime firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    DateTime lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    Map<String, double> monthlyDataMap = Map.fromIterable(
      List.generate(lastDayOfMonth.day,
          (index) => firstDayOfMonth.add(Duration(days: index))),
      key: (date) => date.toString().split(' ')[0],
      value: (date) => 0.0,
    );

    for (var record in records) {
      if (monthlyDataMap.containsKey(record.date)) {
        monthlyDataMap[record.date] = record.value;
      }
    }

    setState(() {
      _monthlyData = monthlyDataMap.entries
          .map((entry) => _RecordData(date: entry.key, value: entry.value))
          .toList();
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _fetchMonthlyData();
    });
  }

  void _nextMonth() {
    if (_currentMonth
        .isBefore(DateTime(DateTime.now().year, DateTime.now().month, 1))) {
      setState(() {
        _currentMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
        _fetchMonthlyData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('グラフ'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedPeriod,
            onChanged: (String? newValue) {
              setState(() {
                if (newValue != null) {
                  _selectedPeriod = newValue;
                }
              });
            },
            items: ['週', '月'].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedGoal,
              onChanged: (String? newValue) {
                if (newValue != null && _goals.contains(newValue)) {
                  setState(() {
                    _selectedGoal = newValue;
                    _updateGoalData();
                  });
                }
              },
              items: _goals.map<DropdownMenuItem<String>>((String goal) {
                return DropdownMenuItem<String>(
                  value: goal,
                  child: Text(goal),
                );
              }).toList(),
            ),
          ),
          if (_selectedPeriod == '月') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _previousMonth,
                ),
                Text('${_currentMonth.year}年${_currentMonth.month}月'),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ],
          Expanded(
            child: _selectedPeriod == '週'
                ? _buildWeeklyChart()
                : _buildMonthlyChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: _weeklyData.isNotEmpty
            ? _weeklyData.map((e) => e.value).reduce((a, b) => a > b ? a : b) +
                10
            : 10,
        title: AxisTitle(text: _goalUnit),
        labelFormat: '{value}$_goalUnit',
      ),
      title: ChartTitle(text: '直近一週間のデータ'),
      series: <ChartSeries>[
        LineSeries<_RecordData, String>(
          dataSource: _weeklyData,
          xValueMapper: (_RecordData data, _) =>
              data.date.split('-').last + '日',
          yValueMapper: (_RecordData data, _) => data.value,
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: _monthlyData.isNotEmpty
            ? _monthlyData.map((e) => e.value).reduce((a, b) => a > b ? a : b) +
                10
            : 10,
        title: AxisTitle(text: _goalUnit),
        labelFormat: '{value}$_goalUnit',
      ),
      title: ChartTitle(text: '${_currentMonth.month}月のデータ'),
      series: <ChartSeries>[
        LineSeries<_RecordData, String>(
          dataSource: _monthlyData,
          xValueMapper: (_RecordData data, _) =>
              data.date.split('-').last + '日',
          yValueMapper: (_RecordData data, _) => data.value,
        ),
      ],
    );
  }
}

class _RecordData {
  final String date;
  final double value;

  _RecordData({required this.date, required this.value});
}
