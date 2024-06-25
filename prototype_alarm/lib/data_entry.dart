import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataEntryPage extends StatefulWidget {
  @override
  _DataEntryPageState createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(labelText: 'Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _unitController,
              decoration: InputDecoration(labelText: 'Unit'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveData,
              child: Text('Save Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    final date = _dateController.text;
    final category = _categoryController.text;
    final value = int.tryParse(_valueController.text) ?? 0;
    final unit = _unitController.text;

    if (date.isNotEmpty && category.isNotEmpty && unit.isNotEmpty) {
      await FirebaseFirestore.instance.collection('data').add({
        'date': date,
        'category': category,
        'value': value,
        'unit': unit,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data Saved')));
    }
  }
}
