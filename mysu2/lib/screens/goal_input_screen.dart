import 'package:flutter/material.dart';
import 'camera_screen.dart'; // 新しい画面をインポート

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({Key? key}) : super(key: key);

  @override
  _AddDataScreenState createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final TextEditingController _recordController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  String? _selectedCategory;
  String? _newCategory;
  final List<String> _categories = ['Category1', 'Category2', 'Category3'];

  void _saveData() {
    // 保存処理をここに実装
    print('Record: ${_recordController.text}');
    print('DATA: ${_dataController.text}');
    print('Selected Category: $_selectedCategory');
    print('New Category: $_newCategory');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data saved successfully')),
    );
  }

  void _onCameraPressed() {
    // 画面遷移の実装
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  }

  void _onPlusPressed() {
    // ＋ボタンが押されたときの処理をここに実装
    print('Plus button pressed');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plus button pressed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt, size: 100),
                  onPressed: _onCameraPressed,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.add_circle, size: 30, color: Colors.red),
                    onPressed: _onPlusPressed,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _recordController,
              decoration: InputDecoration(
                labelText: 'Record',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _dataController,
              decoration: InputDecoration(
                labelText: 'DATA',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '既存項目選択',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '新規項目追加',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        _newCategory = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveData,
              child: Text('保存', style: TextStyle(fontSize: 24)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
