import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
  //カレンダーのUIを作る
  DateTime _selectedDay = DateTime.now();
  //現在選択されている日付を保持
  List<String> _imageUrls = [];
  final Map<DateTime, List<String>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    //画面が初期化されたとき，画像を取得
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    //Firebase Storageから画像のURLを取得(非同期)
    FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://camera-ea94f.appspot.com');
    final ListResult result = await storage.ref('downloads').listAll();
    final List<String> urls = [];
    for (var ref in result.items) {
      final String url = await ref.getDownloadURL();
      // 各ファイルのダウンロードURLを取得する
      urls.add(url);
    }
    setState(() {
      _imageUrls = urls;
    });
  }

  List<String> _getImagesForDay(DateTime day) {
    //指定した日付に対応する画像のURLをリストで返す
    final String formattedDay = DateFormat('yyyyMMdd').format(day);
    return _imageUrls
        .where((url) => url.contains(formattedDay))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final imagesForSelectedDay = _getImagesForDay(_selectedDay);
    // 選択された日付に対応する画像のURLリストを取得する
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          TableCalendar(
            // TableCalendarウィジェットを使用してカレンダーを表示する
            focusedDay: _selectedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            calendarFormat: _calendarFormat,
            onFormatChanged: _onFormatChanged,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                // 日付が選択されたときに選択日付を更新
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
                  color: Color.fromARGB(255, 0, 0, 0), // 枠線の色を指定
                  width: 2.0, // 枠線の太さを指定
                ),
              ),
              defaultTextStyle: TextStyle(color: Colors.black), // カレンダーの日付の文字色を黒に設定
            ),
          ),
          Expanded(
            // 選択された日付に対応する画像がない場合はメッセージを表示し、ある場合はカルーセルスライダーで画像を表示する
            child: imagesForSelectedDay.isEmpty
                ? Center(child: Text('No images for selected day'))
                : CarouselSlider(
                    options: CarouselOptions(height: 400.0),
                    items: imagesForSelectedDay.map((url) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Image.network(url);
                          //選択された画像のURLを返す
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
    //表示する期間を変える
    setState(() {
      _calendarFormat = format;
    });
  }
}