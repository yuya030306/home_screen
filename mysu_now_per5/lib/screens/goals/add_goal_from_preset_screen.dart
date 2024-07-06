import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'set_goal_value_screen.dart';
import 'edit_presets_screen.dart';

class AddGoalFromPresetScreen extends StatefulWidget {
  @override
  _AddGoalFromPresetScreenState createState() => _AddGoalFromPresetScreenState();
}

class _AddGoalFromPresetScreenState extends State<AddGoalFromPresetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目標を追加'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('presetGoals').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var presets = snapshot.data!.docs.map((doc) => {
                  'id': doc.id,
                  'goal': (doc.data() as Map<String, dynamic>)['goal'].toString(),
                  'unit': (doc.data() as Map<String, dynamic>)['unit']?.toString() ?? '',
                }).toList();
                return ListView.builder(
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        title: Text(
                          presets[index]['goal'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        subtitle: Text(
                          '単位: ${presets[index]['unit']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetGoalValueScreen(
                                selectedPreset: presets[index]['goal'],
                                selectedUnit: presets[index]['unit'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditPresetsScreen()),
                );
              },
              child: const Text('プリセットを編集'),
            ),
          ),
        ],
      ),
    );
  }
}
