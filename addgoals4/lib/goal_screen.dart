import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GoalScreen extends StatefulWidget {
  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  String _goalText = '';
  String _goalUnit = '';
  DateTime? _selectedDate;
  List<Map<String, String>> _presets = [];
  String? _selectedPreset;
  String? _selectedUnit;
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('presetGoals').get();
    setState(() {
      _presets = snapshot.docs
          .where((doc) => doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('goal'))
          .map((doc) => {
        'goal': (doc.data() as Map<String, dynamic>)['goal'].toString(),
        'unit': (doc.data() as Map<String, dynamic>).containsKey('unit')
            ? (doc.data() as Map<String, dynamic>)['unit'].toString()
            : ''
      })
          .toList();
    });
  }

  void _selectPresetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a Preset'),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('presetGoals').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var presets = snapshot.data!.docs
                    .where((doc) => doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('goal'))
                    .map((doc) => {
                  'goal': (doc.data() as Map<String, dynamic>)['goal'].toString(),
                  'unit': (doc.data() as Map<String, dynamic>).containsKey('unit')
                      ? (doc.data() as Map<String, dynamic>)['unit'].toString()
                      : ''
                })
                    .toList();
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: presets.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(presets[index]['goal']!),
                      subtitle: Text(presets[index]['unit']!),
                      onTap: () {
                        setState(() {
                          _selectedPreset = presets[index]['goal'];
                          _selectedUnit = presets[index]['unit'];
                          _goalText = presets[index]['goal']!;
                          _goalUnit = presets[index]['unit']!;
                          _goalController.text = presets[index]['goal']!; // Update the text field
                          _unitController.text = presets[index]['unit']!; // Update the text field
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToEditPresets() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPresetsScreen(onPresetsChanged: _loadPresets)),
    ).then((_) => _loadPresets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Goal'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _navigateToEditPresets,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                onPressed: _selectPresetDialog,
                child: Text('Select Preset'),
              ),
              TextFormField(
                controller: _goalController,
                decoration: InputDecoration(labelText: 'Goal'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal';
                  }
                  return null;
                },
                onSaved: (value) {
                  _goalText = value!;
                },
              ),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(labelText: 'Unit'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
                onSaved: (value) {
                  _goalUnit = value!;
                },
              ),
              ListTile(
                title: Text(_selectedDate != null
                    ? DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDate!)
                    : 'Select Deadline'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(picked),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(picked.year, picked.month,
                            picked.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (_selectedDate != null) {
                      FirebaseFirestore.instance.collection('goals').add({
                        'goal': _goalText,
                        'unit': _goalUnit,
                        'deadline': _selectedDate,
                      }).then((_) {
                        Navigator.of(context).pop();
                      });
                    }
                  }
                },
                child: Text('Add Goal'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('goals')
                      .orderBy('deadline')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var goal = snapshot.data!.docs[index];
                        var data = goal.data() as Map<String, dynamic>?; // Null safety
                        return ListTile(
                          title: Text(goal['goal']),
                          subtitle: Text(
                              '${data != null && data.containsKey('unit') ? goal['unit'] : ''} - ${DateFormat('yyyy-MM-dd – kk:mm').format((goal['deadline'] as Timestamp).toDate())}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditPresetsScreen extends StatefulWidget {
  final Function onPresetsChanged;

  EditPresetsScreen({required this.onPresetsChanged});

  @override
  _EditPresetsScreenState createState() => _EditPresetsScreenState();
}

class _EditPresetsScreenState extends State<EditPresetsScreen> {
  List<Map<String, String>> _presets = [];
  final List<TextEditingController> _goalControllers = [];
  final List<TextEditingController> _unitControllers = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('presetGoals').get();
    setState(() {
      _presets = snapshot.docs
          .where((doc) => doc.data() != null && (doc.data() as Map<String, dynamic>).containsKey('goal'))
          .map((doc) => {
        'id': doc.id,
        'goal': (doc.data() as Map<String, dynamic>)['goal'].toString(),
        'unit': (doc.data() as Map<String, dynamic>).containsKey('unit')
            ? (doc.data() as Map<String, dynamic>)['unit'].toString()
            : ''
      })
          .toList();
      _goalControllers.clear();
      _unitControllers.clear();
      _goalControllers.addAll(_presets.map((preset) => TextEditingController(text: preset['goal'])));
      _unitControllers.addAll(_presets.map((preset) => TextEditingController(text: preset['unit'])));
    });
  }

  void _addPreset() {
    setState(() {
      var goalController = TextEditingController();
      var unitController = TextEditingController();
      _goalControllers.add(goalController);
      _unitControllers.add(unitController);
      _presets.add({'id': '', 'goal': '', 'unit': ''});
    });
  }

  void _savePresets() {
    for (int i = 0; i < _presets.length; i++) {
      var preset = _presets[i];
      var goal = _goalControllers[i].text;
      var unit = _unitControllers[i].text;
      if (preset['id'] == '') {
        FirebaseFirestore.instance.collection('presetGoals').add({'goal': goal, 'unit': unit});
      } else {
        FirebaseFirestore.instance.collection('presetGoals').doc(preset['id']!).set({'goal': goal, 'unit': unit});
      }
    }
    widget.onPresetsChanged();
    Navigator.of(context).pop();
  }

  void _deletePreset(int index) {
    var preset = _presets[index];
    if (preset['id'] != '') {
      FirebaseFirestore.instance.collection('presetGoals').doc(preset['id']).delete().then((_) {
        setState(() {
          _presets.removeAt(index);
          _goalControllers.removeAt(index);
          _unitControllers.removeAt(index);
        });
      });
    } else {
      setState(() {
        _presets.removeAt(index);
        _goalControllers.removeAt(index);
        _unitControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Presets'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePresets,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Column(
              children: [
                TextFormField(
                  controller: _goalControllers[index],
                  decoration: InputDecoration(labelText: 'Goal'),
                  onChanged: (value) {
                    setState(() {
                      _presets[index]['goal'] = value;
                    });
                  },
                ),
                TextFormField(
                  controller: _unitControllers[index],
                  decoration: InputDecoration(labelText: 'Unit'),
                  onChanged: (value) {
                    setState(() {
                      _presets[index]['unit'] = value;
                    });
                  },
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deletePreset(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addPreset,
      ),
    );
  }
}
