import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ranking_screen.dart';

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({Key? key}) : super(key: key);

  @override
  _AddDataScreenState createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _recordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  Future<void> _addData() async {
    final String user = _userController.text;
    final String record = _recordController.text;
    final String date = _dateController.text;
    final String category = _categoryController.text;

    if (user.isNotEmpty && record.isNotEmpty && date.isNotEmpty && category.isNotEmpty) {
      await FirebaseFirestore.instance.collection('ranking').add({
        'user': user,
        'record': record,
        'date': date,
        'category': category,
      });

      _userController.clear();
      _recordController.clear();
      _dateController.clear();
      _categoryController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _recordController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'User'),
            ),
            TextField(
              controller: _recordController,
              decoration: const InputDecoration(labelText: 'Record'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addData,
              child: const Text('Add Record'),
            ),
          ],
        ),
      ),
    );
  }
}
