import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = "ユーザ名";
  String _avatarUrl = "https://example.com/avatar.jpg";
  Color _avatarColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール'),
      ),
      body: Center(
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
                    image: DecorationImage(
                      image: NetworkImage(_avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.palette, color: Colors.white, size: 35.0),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            username: _username,
                            avatarUrl: _avatarUrl,
                            avatarColor: _avatarColor,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _username = result['username'];
                          _avatarUrl = result['avatarUrl'];
                          _avatarColor = result['avatarColor'];
                        });
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
                      avatarUrl: _avatarUrl,
                      avatarColor: _avatarColor,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    _username = result['username'];
                    _avatarUrl = result['avatarUrl'];
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
}

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String avatarUrl;
  final Color avatarColor;

  EditProfileScreen({
    required this.username,
    required this.avatarUrl,
    required this.avatarColor,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late String _selectedAvatar;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _selectedAvatar = widget.avatarUrl;
    _selectedColor = widget.avatarColor;
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
                    image: DecorationImage(
                      image: NetworkImage(_selectedAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.palette, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AvatarSelectionDialog(
                          initialAvatarUrl: _selectedAvatar,
                          initialColor: _selectedColor,
                          onAvatarSelected: (avatarUrl, avatarColor) {
                            setState(() {
                              _selectedAvatar = avatarUrl;
                              _selectedColor = avatarColor;
                            });
                          },
                        ),
                      );
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
              onPressed: () {
                Navigator.pop(context, {
                  'username': _usernameController.text,
                  'avatarUrl': _selectedAvatar,
                  'avatarColor': _selectedColor,
                });
              },
              child: Text('保存'),
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
  final String initialAvatarUrl;
  final Color initialColor;
  final Function(String, Color) onAvatarSelected;

  AvatarSelectionDialog({
    required this.initialAvatarUrl,
    required this.initialColor,
    required this.onAvatarSelected,
  });

  @override
  _AvatarSelectionDialogState createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  late String _selectedAvatar;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.initialAvatarUrl;
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
                image: DecorationImage(
                  image: NetworkImage(_selectedAvatar),
                  fit: BoxFit.cover,
                ),
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
            widget.onAvatarSelected(_selectedAvatar, _selectedColor);
            Navigator.pop(context);
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
