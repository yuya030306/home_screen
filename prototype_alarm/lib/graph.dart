import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  Map<String, List<FlSpot>> _dataPoints = {};
  String _selectedCategory = '';
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('data').get();
    Map<String, List<FlSpot>> tempDataPoints = {};

    querySnapshot.docs.forEach((doc) {
      String category = doc['category'];
      String date = doc['date'];
      double value = doc['value'].toDouble();
      DateTime dateTime = DateTime.parse(date);
      double xValue = dateTime.difference(DateTime.now().subtract(Duration(days: 7))).inDays.toDouble();

      if (!tempDataPoints.containsKey(category)) {
        tempDataPoints[category] = [];
      }
      tempDataPoints[category]!.add(FlSpot(xValue, value));
    });

    setState(() {
      _dataPoints = tempDataPoints;
      _categories = _dataPoints.keys.toList();
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories[0];
      }
    });
  }

  Future<void> _addCategory(String category) async {
    if (!_categories.contains(category)) {
      setState(() {
        _categories.add(category);
        _dataPoints[category] = [];
        if (_selectedCategory.isEmpty) {
          _selectedCategory = category;
        }
      });

      // Firestoreにカテゴリーを保存
      await FirebaseFirestore.instance.collection('data').add({'name': category});
    }
  }

  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('カテゴリーを追加'),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(hintText: "カテゴリー名を入力してください"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('追加'),
              onPressed: () async {
                if (categoryController.text.isNotEmpty) {
                  await _addCategory(categoryController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Graph Drawing App'),
        actions: [
          IconButton(
            icon: Icon(Icons.alarm),
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (_categories.isEmpty)
              Center(
                child: Text('カテゴリーを追加してください。'),
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                      items: _categories.map<DropdownMenuItem<String>>((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            Expanded(
              child: _dataPoints.isNotEmpty
                  ? LineChart(
                LineChartData(
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          String unit = _dataPoints[_selectedCategory]!.isEmpty || _dataPoints[_selectedCategory]![0].y == 0 ? '単位' : '分';
                          return Text('${value.toInt()} $unit');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          DateTime date = DateTime.now().subtract(Duration(days: 7)).add(Duration(days: value.toInt()));
                          return Text(DateFormat.Md().format(date));
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dataPoints[_selectedCategory]!,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                    ),
                  ],
                  minX: 1,
                  maxX: 7,
                  minY: 0,
                  maxY: (_dataPoints[_selectedCategory]?.fold<double>(0, (max, spot) => spot.y > max ? spot.y : max) ?? 0) + 10,
                ),
              )
                  : Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
