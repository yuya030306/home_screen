import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CalendarScreen extends StatefulWidget {
  @override
  final CameraDescription camera;
  final String userId;
  const CalendarScreen({Key? key, required this.camera, required this.userId})
      : super(key: key);
  _CalendarScreenState createState() => _CalendarScreenState();
}

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final List<String>? goalsForDay;

  const FullScreenImageScreen({
    Key? key,
    required this.imageUrl,
    required this.goalsForDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uniqueGoals = goalsForDay != null ? goalsForDay!.toSet().toList() : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
              if (uniqueGoals != null && uniqueGoals.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '達成した目標',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        ...uniqueGoals.map((goal) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '• $goal',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'この日の記録は取得できませんでした',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
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

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Map<String, String>> _imageUrls = [];
  Map<String, String> _goals = {};
  bool _isNetworkError = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _currentImageIndex = 0;
  List <String>? _goalForSelectedDay;
  List<_RecordData> _monthlyData = [];
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _fetchGoalForDay(_selectedDay);
  }

  Future<void> _fetchImages() async {
    try {
      FirebaseStorage storage =
      FirebaseStorage.instanceFor(bucket: 'gs://login-9ab9b.appspot.com');
      final ListResult result = await storage.ref(widget.userId).listAll();
      final List<Map<String, String>> urls = [];
      for (var ref in result.items) {
        final String url = await ref.getDownloadURL();
        final String name = ref.name;
        urls.add({'url': url, 'name': name});
      }
      setState(() {
        _imageUrls = urls;
        _isNetworkError = false;
      });
    } on SocketException {
      setState(() {
        _isNetworkError = true;
      });
    } catch (e) {
      setState(() {
        _isNetworkError = true;
      });
    }
  }

  Future<void> _fetchGoalForDay(DateTime day) async {
    try {
      final DateTime startOfDay = DateTime(day.year, day.month, day.day);
      final DateTime endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: widget.userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final List<String> goals = [];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String goal = data['goal'];
          goals.add(goal);
        }

        setState(() {
          _goalForSelectedDay = goals.isEmpty ? null : goals;
        });
      } else {
        setState(() {
          _goalForSelectedDay = null;
        });
      }
    } catch (e) {
      setState(() {
        _isNetworkError = true;
      });
    }
  }

  List<Map<String, String>> _getImagesForDay(DateTime day) {
    final String formattedDay = DateFormat('yyyyMMdd').format(day);
    return _imageUrls
        .where((image) => image['name']!.contains(formattedDay))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final imagesForSelectedDay = _getImagesForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color.fromARGB(255, 255, 203, 144)],
            stops: [0.5, 1],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.5,
              child: TableCalendar(
                focusedDay: _selectedDay,
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                calendarFormat: _calendarFormat,
                onFormatChanged: _onFormatChanged,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    if (_selectedDay != selectedDay) {
                      _selectedDay = selectedDay;
                      _currentImageIndex = 0;
                    }
                  });
                  _fetchGoalForDay(selectedDay);
                  print('Selected day: $selectedDay');

                },
                headerStyle: HeaderStyle(
                  formatButtonTextStyle:
                  const TextStyle(color: Color.fromARGB(255, 1, 12, 78)),
                  formatButtonDecoration: BoxDecoration(
                    color: Color.fromARGB(255, 247, 178, 30),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  titleTextFormatter: (date, _) {
                    String M = '';
                    if (_calendarFormat == CalendarFormat.month) {
                      M = date.month.toString() + '月';
                    } else if (_calendarFormat == CalendarFormat.twoWeeks) {
                      M = date.month.toString() + '月' + ' 2週';
                    } else if (_calendarFormat == CalendarFormat.week) {
                      M = date.month.toString() + '月' + ' 週次';
                    }
                    return M;
                  },
                  titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  dowTextFormatter: (date, locale) {
                    switch (date.weekday) {
                      case DateTime.sunday:
                        return '日';
                      case DateTime.monday:
                        return '月';
                      case DateTime.tuesday:
                        return '火';
                      case DateTime.wednesday:
                        return '水';
                      case DateTime.thursday:
                        return '木';
                      case DateTime.friday:
                        return '金';
                      case DateTime.saturday:
                        return '土';
                      default:
                        return '';
                    }
                  },
                  weekendStyle: TextStyle()
                      .copyWith(color: Color.fromARGB(255, 226, 147, 0)),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color.fromARGB(255, 224, 132, 70),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.black),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final imagesForDay = _getImagesForDay(day);
                    if (imagesForDay.isNotEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          image: DecorationImage(
                            image: NetworkImage(imagesForDay.first['url']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Center(child: Text(day.day.toString()));
                    }
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final imagesForDay = _getImagesForDay(day);
                    if (imagesForDay.isNotEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(imagesForDay.first['url']!),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: Colors.black,
                            width: 2.0,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 2.0,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            if (_isNetworkError)
              Center(
                  child: Text('ネットワークエラーが発生しました。インターネット接続を確認してください。',
                      style: TextStyle(color: Colors.red))),
            if (!_isNetworkError && imagesForSelectedDay.isEmpty)
              Center(child: Text('選択されている日付の写真は見つかりませんでした'))
            else if (!_isNetworkError)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _currentImageIndex > 0
                              ? () {
                            setState(() {
                              _currentImageIndex = (_currentImageIndex -
                                  1 +
                                  imagesForSelectedDay.length) %
                                  imagesForSelectedDay.length;
                            });
                          }
                              : null,
                          child: Icon(Icons.arrow_back),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            textStyle: TextStyle(fontSize: 20),
                            backgroundColor: Colors.white,
                            foregroundColor: Color.fromARGB(255, 255, 185, 93),
                            shape: CircleBorder(),
                            side: BorderSide(
                                color: Color.fromARGB(255, 255, 217, 168),
                                width: 2),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageScreen(
                                  imageUrl: imagesForSelectedDay[_currentImageIndex]['url']!,
                                  goalsForDay: _goalForSelectedDay,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.width * 0.5,
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              shape: BoxShape.rectangle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                imagesForSelectedDay[_currentImageIndex]['url']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _currentImageIndex <
                              imagesForSelectedDay.length - 1
                              ? () {
                            setState(() {
                              _currentImageIndex =
                                  (_currentImageIndex + 1) %
                                      imagesForSelectedDay.length;
                            });
                          }
                              : null,
                          child: Icon(Icons.arrow_forward),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                            backgroundColor: Colors.white,
                            foregroundColor: Color.fromARGB(255, 255, 185, 93),
                            shape: CircleBorder(),
                            side: BorderSide(
                                color: Color.fromARGB(255, 255, 217, 168),
                                width: 2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                    Text(
                      '${DateFormat('yyyy年MM月dd日').format(_selectedDay)} - ${_currentImageIndex + 1}枚目',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }
}

class _RecordData {
  final String date;
  final double value;

  _RecordData({required this.date, required this.value});
}
