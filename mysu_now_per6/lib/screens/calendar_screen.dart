import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';

class CalendarScreen extends StatefulWidget {
  @override
  final CameraDescription camera;
  final String userId;
  const CalendarScreen({Key? key, required this.camera, required this.userId}) : super(key: key);
  _CalendarScreenState createState() => _CalendarScreenState();
}

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Map<String, String>> _imageUrls = [];
  final Map<DateTime, List<String>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://login-9ab9b.appspot.com');
    final ListResult result = await storage.ref(widget.userId).listAll();
    final List<Map<String, String>> urls = [];
    for (var ref in result.items) {
      final String url = await ref.getDownloadURL();
      final String name = ref.name;
      urls.add({'url': url, 'name': name});
    }
    setState(() {
      _imageUrls = urls;
    });
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
      appBar: AppBar(title: Text('Calendar')),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          TableCalendar(
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
            },
            headerStyle: HeaderStyle(
              formatButtonTextStyle: const TextStyle(color: Color.fromARGB(255, 0, 15, 100)),
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
                fontSize: 20.0,
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
              weekendStyle: TextStyle().copyWith(color: Color.fromARGB(255, 226, 147, 0)),
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
          if (imagesForSelectedDay.isEmpty)
            Center(child: Text('選択されている日付の写真は見つかりませんでした'))
          else
            Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  child: SingleChildScrollView(
                      child: Column(children: [
                        Image.network(
                          imagesForSelectedDay[_currentImageIndex]['url']!,
                          fit: BoxFit.cover,
                        ),
                      ],)

                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _currentImageIndex > 0
                          ? () {
                        setState(() {
                          _currentImageIndex = (_currentImageIndex - 1 + imagesForSelectedDay.length) % imagesForSelectedDay.length;
                        });
                      }
                          : null,
                      child: Icon(Icons.arrow_back),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: _currentImageIndex < imagesForSelectedDay.length - 1
                          ? () {
                        setState(() {
                          _currentImageIndex = (_currentImageIndex + 1) % imagesForSelectedDay.length;
                        });
                      }
                          : null,
                      child: Icon(Icons.arrow_forward),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '${DateFormat('yyyy年MM月dd日').format(_selectedDay)} - ${_currentImageIndex + 1}枚目',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }
}