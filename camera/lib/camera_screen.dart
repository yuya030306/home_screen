import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;
  XFile? _imageFile;

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
      setState(() {
        _imageFile = image;
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
    if (_imageFile == null) return;

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(await _imageFile!.readAsBytes());

      FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://camera-ea94f.appspot.com');
      Reference ref = storage.ref().child('uploads/${DateTime.now().millisecondsSinceEpoch}.png');
      UploadTask uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Picture uploaded to Firebase!')));
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _imageFile == null
                ? CameraPreview(_controller)
                : Image.file(File(_imageFile!.path));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: _imageFile == null
          ? FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: _isTakingPicture ? null : _takePicture,
      )
          : FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: _savePicture,
      ),
    );
  }
}
