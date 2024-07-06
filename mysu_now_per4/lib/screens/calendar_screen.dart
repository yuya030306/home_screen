import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // 必要なインポート
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart'; // 必要なインポート

//test git

class CalendarScreen extends StatefulWidget {
  @override
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
  List<String> _imageUrls = [];
  final Map<DateTime, List<String>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://camera-ea94f.appspot.com');
    final ListResult result = await storage.ref('downloads').listAll();
    final List<String> urls = [];
    for (var ref in result.items) {
      final String url = await ref.getDownloadURL();
      urls.add(url);
    }
    setState(() {
      _imageUrls = urls;
    });
  }

  List<String> _getImagesForDay(DateTime day) {
    final String formattedDay = DateFormat('yyyyMMdd').format(day);
    return _imageUrls.where((url) => url.contains(formattedDay)).toList();
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
                _selectedDay = selectedDay;
              });
            },
            headerStyle: HeaderStyle(
              formatButtonTextStyle: const TextStyle(color: Color.fromARGB(255, 0, 15, 100)),
              formatButtonDecoration: BoxDecoration(
                color: Color.fromARGB(255, 30, 167, 247),
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
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 26, 79, 192),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromARGB(255, 0, 0, 0),
                  width: 2.0,
                ),
              ),
              defaultTextStyle: TextStyle(color: Colors.black),
            ),
          ),
          Expanded(
            child: imagesForSelectedDay.isEmpty
                ? Center(child: Text('No images for selected day'))
                : CarouselSlider(
              options: CarouselOptions(height: 400.0),
              items: imagesForSelectedDay.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(url);
                  },
                );
              }).toList(),
            ),
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
