import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'プロフィールアプリ',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "ユーザ名";
  Color _avatarColor = Colors.orange;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      String userId = _currentUser!.uid;
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          setState(() {
            _username = documentSnapshot['username'];
            _avatarColor = documentSnapshot['avatarColor'] != null
                ? Color(int.parse(documentSnapshot['avatarColor'], radix: 16))
                : Colors.orange; // デフォルトカラーを設定
            _isLoading = false;
          });
        } else {
          print('Document does not exist on the database');
          setState(() {
            _isLoading = false;
          });
        }
      }).catchError((error) {
        print('Error getting document: $error');
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
          child: Container(
            width: 280, // 白い枠の幅を大きく
            height: 370, // 白い枠の高さを大きく
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _avatarColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  _username,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          username: _username,
                          avatarColor: _avatarColor,
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _username = result['username'];
                        _avatarColor = result['avatarColor'];
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: Text(
                    'プロフィール編集',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String username;
  final Color avatarColor;

  EditProfileScreen({
    required this.username,
    required this.avatarColor,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late Color _selectedColor;
  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _selectedColor = widget.avatarColor;
  }

  Future<bool> _isUsernameTaken(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  void _showUsernameTakenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
        content: Text('既にそのユーザ名は使用されています。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    String newUsername = _usernameController.text;

    if (newUsername == widget.username && _selectedColor == widget.avatarColor) {
      Navigator.pop(context, {
        'username': newUsername,
        'avatarColor': _selectedColor,
      });
      return;
    }

    if (newUsername != widget.username) {
      setState(() {
        _isCheckingUsername = true;
      });

      bool isTaken = await _isUsernameTaken(newUsername);
      setState(() {
        _isCheckingUsername = false;
      });

      if (isTaken) {
        _showUsernameTakenDialog();
        return;
      }
    }

    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'username': newUsername,
      'avatarColor': _selectedColor.value.toRadixString(16),
    });

    Navigator.pop(context, {
      'username': newUsername,
      'avatarColor': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール編集'),
        backgroundColor: Colors.orange,
      ),
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: Center(
          child: Container(
            width: 300, // 白い枠の幅を小さく
            height: 370, // 白い枠の高さを小さく
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.palette, color: Colors.white),
                        onPressed: () async {
                          final color = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AvatarSelectionDialog(
                                initialColor: _selectedColor,
                              ),
                            ),
                          );

                          if (color != null) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'ユーザ名',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isCheckingUsername ? null : _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: _isCheckingUsername
                      ? CircularProgressIndicator()
                      : Text('保存', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}

class AvatarSelectionDialog extends StatelessWidget {
  final Color initialColor;

  AvatarSelectionDialog({
    required this.initialColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('アイコン編集'),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: initialColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text('カラー選択'),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _colorOption(context, Colors.red),
                  _colorOption(context, Colors.green),
                  _colorOption(context, Colors.blue),
                  _colorOption(context, Colors.yellow),
                  _colorOption(context, Colors.orange),
                  _colorOption(context, Colors.purple),
                  _colorOption(context, Colors.brown),
                  _colorOption(context, Colors.pink),
                  _colorOption(context, Colors.cyan),
                  _colorOption(context, Colors.lime),
                  _colorOption(context, Colors.indigo),
                  _colorOption(context, Colors.teal),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, initialColor);
          },
          child: Text('選択'),
        ),
      ],
    );
  }

  Widget _colorOption(BuildContext context, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: color == initialColor ? Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    paint.color = Colors.orange.shade200;

    path.reset();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
  }