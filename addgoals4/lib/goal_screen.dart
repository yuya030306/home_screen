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
  DateTime? _selectedDate;
  List<String> _presets = ['Exercise', 'Read a book', 'Learn a new skill'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Goal          edit preset'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditPresetsScreen(presets: _presets, onPresetsChanged: (newPresets) {
                  setState(() {
                    _presets = newPresets;
                  });
                })),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select a preset'),
                items: _presets.map((preset) {
                  return DropdownMenuItem(
                    value: preset,
                    child: Text(preset),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _goalText = value ?? '';
                  });
                },
                onSaved: (value) {
                  _goalText = value ?? '';
                },
              ),
              TextFormField(
                initialValue: _goalText,
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
                        'deadline': _selectedDate,
                      }).then((_) {
                        Navigator.of(context).pop();
                      });
                    }
                  }
                },
                child: Text('Add Goal'),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('goals')
                      .orderBy('deadline')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var goal = snapshot.data!.docs[index];
                        return ListTile(
                          title: Text(goal['goal']),
                          subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm')
                              .format((goal['deadline'] as Timestamp).toDate())),
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
  final List<String> presets;
  final Function(List<String>) onPresetsChanged;

  EditPresetsScreen({required this.presets, required this.onPresetsChanged});

  @override
  _EditPresetsScreenState createState() => _EditPresetsScreenState();
}

class _EditPresetsScreenState extends State<EditPresetsScreen> {
  late List<String> _presets;

  @override
  void initState() {
    super.initState();
    _presets = List.from(widget.presets);
  }

  void _addPreset() {
    setState(() {
      _presets.add('');
    });
  }

  void _savePresets() {
    widget.onPresetsChanged(_presets.where((preset) => preset.isNotEmpty).toList());
    Navigator.of(context).pop();
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
            title: TextFormField(
              initialValue: _presets[index],
              onChanged: (value) {
                setState(() {
                  _presets[index] = value;
                });
              },
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _presets.removeAt(index);
                });
              },
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
