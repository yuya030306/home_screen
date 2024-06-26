import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<String>> _photoUrls;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _photoUrls = {};
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    ListResult result = await storage.ref('uploads').listAll();
    Map<DateTime, List<String>> newPhotoUrls = {};

    for (var item in result.items) {
      String url = await item.getDownloadURL();
      DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(item.name.split('.').first));
      if (newPhotoUrls.containsKey(date)) {
        newPhotoUrls[date]!.add(url);
      } else {
        newPhotoUrls[date] = [url];
      }
    }

    setState(() {
      _photoUrls = newPhotoUrls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: DateTime.now(),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
          ),
          Expanded(
            child: _photoUrls[_selectedDay] == null
                ? Center(child: Text('No photos for this day'))
                : ListView(
              children: _photoUrls[_selectedDay]!
                  .map((url) => Image.network(url))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
