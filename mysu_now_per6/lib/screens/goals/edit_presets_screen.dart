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

  void _addPreset() async {
    if (_goalController.text.isNotEmpty && _unitController.text.isNotEmpty && user != null) {
      if (RegExp(r'^[0-9]+$').hasMatch(_unitController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('単位には数値を入力できません')),
        );
      } else {
        FirebaseFirestore.instance.collection('presetGoals').add({
          'goal': _goalController.text,
          'unit': _unitController.text,
          'userId': user?.uid,
        });
        _goalController.clear();
        _unitController.clear();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('目標と単位を入力してください')),
      );
    }
  }

  void _deletePreset(String id) {
    FirebaseFirestore.instance.collection('presetGoals').doc(id).delete();
  }

  void _updatePreset(String id, String field, String value) {
    FirebaseFirestore.instance.collection('presetGoals').doc(id).update({
      field: value,
    });
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
                  var presets = snapshot.data!.docs.map((doc) => {
                    'id': doc.id,
                    'goal': (doc.data() as Map<String, dynamic>)['goal']?.toString() ?? '',
                    'unit': (doc.data() as Map<String, dynamic>)['unit']?.toString() ?? '',
                  }).toList();
                  return ListView.builder(
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      var preset = presets[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                              _updatePreset(preset['id']!, 'unit', value);
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
