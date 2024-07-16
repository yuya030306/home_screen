import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import 'set_goal_value_screen.dart';
import 'edit_presets_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddGoalFromPresetScreen extends StatefulWidget {
  @override
  _AddGoalFromPresetScreenState createState() => _AddGoalFromPresetScreenState();
}

class _AddGoalFromPresetScreenState extends State<AddGoalFromPresetScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return MaterialApp(
        theme: appTheme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('目標を追加'),
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
          title: const Text('目標を追加'),
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
      ),
    );
  }
}
