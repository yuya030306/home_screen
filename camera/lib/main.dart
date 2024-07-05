import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

DateTime? _selectedDay;
//fullscreen等で使うためにここに置く

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: HomeScreen(camera: camera),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final CameraDescription camera;

  const HomeScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TakePictureScreen(camera: camera)),
                );
              },
              child: Text('Camera'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalendarScreen()),
                );
              },
              child: Text('Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;
    setState(() {
      _isTakingPicture = true;
    });

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/$timestamp.png';
      final file = File(path);
      await file.writeAsBytes(await image.readAsBytes());

      setState(() {
        _imagePath = path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    } finally {
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  Future<void> _savePicture() async {
    if (_imagePath == null) return;

    try {
      FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://camera-ea94f.appspot.com');
      String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
      String fileName = '${formattedDate}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = storage.ref().child('downloads/$fileName');
      UploadTask uploadTask = ref.putFile(File(_imagePath!));
      await uploadTask.whenComplete(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Picture taken and uploaded!')));
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      });

      Navigator.pop(context); // Go back to the home screen after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      body: _imagePath == null
          ? FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            )
          : Image.file(File(_imagePath!)),
      floatingActionButton: _imagePath == null
          ? FloatingActionButton(
              child: Icon(Icons.camera_alt),
              onPressed: _isTakingPicture ? null : _takePicture,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  child: Icon(Icons.save),
                  onPressed: _savePicture,
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  child: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _imagePath = null;
                    });
                  },
                ),
              ],
            ),
    );
  }
}

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
    FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://camera-ea94f.appspot.com');
    final ListResult result = await storage.ref('downloads').listAll();
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
              weekendStyle: TextStyle().copyWith(color: Colors.red),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 26, 79, 192),
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
                  width: 300,
                  height: 300,
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