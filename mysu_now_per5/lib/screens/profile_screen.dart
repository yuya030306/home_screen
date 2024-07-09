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
        primarySwatch: Colors.blue,
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
  Color _avatarColor = Colors.blue;
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
                : Colors.blue; // デフォルトカラーを設定
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
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
                    color: _avatarColor,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.palette, color: Colors.white, size: 35.0),
                    onPressed: () async {
                      final color = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvatarSelectionDialog(
                            initialColor: _avatarColor,
                          ),
                        ),
                      );

                      if (color != null) {
                        setState(() {
                          _avatarColor = color;
                        });
                        _saveAvatarColor(color);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              _username,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 70),
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
              child: Text('プロフィール編集'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAvatarColor(Color color) async {
    if (_currentUser != null) {
      String userId = _currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'avatarColor': color.value.toRadixString(16),
      });
    }
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedColor,
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
              decoration: InputDecoration(labelText: 'ユーザ名'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isCheckingUsername ? null : _saveProfileChanges,
              child: _isCheckingUsername
                  ? CircularProgressIndicator()
                  : Text('保存'),
            ),
          ],
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

class AvatarSelectionDialog extends StatefulWidget {
  final Color initialColor;

  AvatarSelectionDialog({
    required this.initialColor,
  });

  @override
  _AvatarSelectionDialogState createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('アイコン編集'),
      content: SingleChildScrollView(
      child: Column(
      children: [
      Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _selectedColor,
      ),
    ),
    SizedBox(height: 20),
    Text('カラー選択'),
    SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _colorOption(Colors.red),
            _colorOption(Colors.green),
            _colorOption(Colors.blue),
            _colorOption(Colors.yellow),
            _colorOption(Colors.orange),
            _colorOption(Colors.purple),
            _colorOption(Colors.brown),
            _colorOption(Colors.pink),
            _colorOption(Colors.cyan),
            _colorOption(Colors.lime),
            _colorOption(Colors.indigo),
            _colorOption(Colors.teal),
          ],
        ),
      ],
      ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, _selectedColor);
          },
          child: Text('選択'),
        ),
      ],
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: _selectedColor == color ? Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}

