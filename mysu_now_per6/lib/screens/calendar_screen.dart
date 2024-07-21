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

  const FullScreenImageScreen({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Image.network(imageUrl, fit: BoxFit.contain),
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
  String? _goalForSelectedDay;
  List<_RecordData> _monthlyData = [];
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _fetchGoals();
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

  Future<void> _fetchGoals() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: widget.userId)
          .get();

      final Map<String, String> goals = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = data['timestamp'];
        final String goal = data['goal'];
        final String formattedDate =
        DateFormat('yyyyMMdd').format(timestamp.toDate());
        goals[formattedDate] = goal;
      }

      setState(() {
        _goals = goals;
      });
    } catch (e) {
      setState(() {
        _isNetworkError = true;
      });
    }
  }

  Future<void> _fetchGoalForDay(DateTime day) async {
    try {
      final String formattedDate = DateFormat('yyyyMMdd').format(day);
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('records')
          .where('userId', isEqualTo: widget.userId)
          .where('timestamp', isEqualTo: formattedDate)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final String goal = data['goal'];

        setState(() {
          _goalForSelectedDay = goal;
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
                                  imageUrl:
                                  imagesForSelectedDay[_currentImageIndex]
                                  ['url']!,
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
                                imagesForSelectedDay[_currentImageIndex]
                                ['url']!,
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
                    SizedBox(height: 8),
                    Text(
                      '${DateFormat('yyyy年MM月dd日').format(_selectedDay)} - ${_currentImageIndex + 1}枚目',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    if (_goalForSelectedDay != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Goal: $_goalForSelectedDay',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
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