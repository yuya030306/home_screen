import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // FirebaseAuthのインポート

class EditPresetsScreen extends StatefulWidget {
  @override
  _EditPresetsScreenState createState() => _EditPresetsScreenState();
}

class _EditPresetsScreenState extends State<EditPresetsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;  // 現在のユーザを取得

  void _addPreset() async {
    if (_goalController.text.isNotEmpty && _unitController.text.isNotEmpty && user != null) {
      FirebaseFirestore.instance.collection('presetGoals').add({
        'goal': _goalController.text,
        'unit': _unitController.text,
        'userId': user?.uid,  // ユーザIDを追加
      });
      _goalController.clear();
      _unitController.clear();
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('プリセットを編集'),
        ),
        body: Center(child: Text('ユーザーが認証されていません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プリセットを編集'),
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
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: TextFormField(
                          initialValue: presets[index]['goal'] ?? '',
                          decoration: InputDecoration(labelText: '目標'),
                          onChanged: (value) {
                            _updatePreset(presets[index]['id']!, 'goal', value);  // String? -> String
                          },
                        ),
                        subtitle: TextFormField(
                          initialValue: presets[index]['unit'] ?? '',
                          decoration: InputDecoration(labelText: '単位'),
                          onChanged: (value) {
                            _updatePreset(presets[index]['id']!, 'unit', value);  // String? -> String
                          },
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePreset(presets[index]['id']!),  // String? -> String
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
    );
  }
}
