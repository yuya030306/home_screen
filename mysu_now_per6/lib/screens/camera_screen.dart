import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String userId;

  const CameraScreen({Key? key, required this.camera, required this.userId}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
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
      FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://login-9ab9b.appspot.com');
      String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
      String fileName = '${formattedDate}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Use userId in the storage path
      Reference ref = storage.ref().child('${widget.userId}/$fileName');
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