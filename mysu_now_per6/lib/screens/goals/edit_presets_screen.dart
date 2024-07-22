import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';

class EditPresetsScreen extends StatefulWidget {
  @override
  _EditPresetsScreenState createState() => _EditPresetsScreenState();
}

class _EditPresetsScreenState extends State<EditPresetsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _addPreset() async {
    if (_goalController.text.isNotEmpty &&
        _unitController.text.isNotEmpty &&
        user != null) {
      bool isDuplicate = await _checkDuplicatePreset(_goalController.text);
      if (isDuplicate) {
        _showErrorDialog('そのプリセット名は既に登録されています。');
        return;
      }

      if (RegExp(r'^[0-9]+$').hasMatch(_unitController.text)) {
        _showErrorDialog('単位に数値は入力できません');
      } else {
        await FirebaseFirestore.instance.collection('presetGoals').add({
          'goal': _goalController.text,
          'unit': _unitController.text,
          'userId': user?.uid,
        });
        _goalController.clear();
        _unitController.clear();
        _refresh();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('目標と単位を入力してください')),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  Future<bool> _checkDuplicatePreset(String goal) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('presetGoals')
        .where('userId', isEqualTo: user?.uid)
        .where('goal', isEqualTo: goal)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _deletePreset(String id) async {
    await FirebaseFirestore.instance.collection('presetGoals').doc(id).delete();
    _refresh();
  }

  void _updatePreset(String id, String field, String value) {
    FirebaseFirestore.instance.collection('presetGoals').doc(id).update({
      field: value,
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
        content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return MaterialApp(
        theme: appTheme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('プリセットを編集'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Center(child: Text('ユーザーが認証されていません')),
        ),
      );
    }

    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('プリセットを編集'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('presetGoals')
                    .where('userId', isEqualTo: user!.uid)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var presets = snapshot.data!.docs
                      .map((doc) => {
                            'id': doc.id,
                            'goal': (doc.data() as Map<String, dynamic>)['goal']
                                    ?.toString() ??
                                '',
                            'unit': (doc.data() as Map<String, dynamic>)['unit']
                                    ?.toString() ??
                                '',
                          })
                      .toList();
                  return ListView.builder(
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      var preset = presets[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: TextFormField(
                            initialValue: preset['goal'] ?? '',
                            decoration: InputDecoration(labelText: '目標'),
                            onChanged: (value) {
                              _updatePreset(preset['id']!, 'goal', value);
                            },
                          ),
                          subtitle: TextFormField(
                            initialValue: preset['unit'] ?? '',
                            decoration: InputDecoration(labelText: '単位'),
                            onChanged: (value) {
                              if (RegExp(r'^[0-9]+$').hasMatch(value)) {
                                _showErrorDialog('単位に数値は入力できません');
                              } else {
                                _updatePreset(preset['id']!, 'unit', value);
                              }
                            },
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePreset(preset['id']!),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _goalController,
                    decoration: InputDecoration(labelText: '目標'),
                  ),
                  TextField(
                    controller: _unitController,
                    decoration: InputDecoration(labelText: '単位'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addPreset,
                    child: Text('プリセットを追加'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
