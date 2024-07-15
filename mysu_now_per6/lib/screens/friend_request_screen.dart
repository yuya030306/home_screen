import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pending_requests_screen.dart';

class FriendRequestScreen extends StatefulWidget {
  final String userId;

  FriendRequestScreen({required this.userId});

  @override
  _FriendRequestScreenState createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _controller = TextEditingController();
  int pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _getPendingRequestsCount();
  }

  Future<void> _sendFriendRequest() async {
    String friendUsername = _controller.text;
    if (friendUsername.isEmpty) return;

    QuerySnapshot query = await _firestore
        .collection('users')
        .where('username', isEqualTo: friendUsername)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ユーザが見つかりませんでした')),
      );
      return;
    }

    String friendId = query.docs.first.id;

    await _firestore.collection('friend_requests').add({
      'from': widget.userId,
      'to': friendId,
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('フレンド申請を送信しました')),
    );

    _controller.clear();
    _getPendingRequestsCount();
  }

  Future<void> _getPendingRequestsCount() async {
    QuerySnapshot query = await _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      pendingRequestsCount = query.docs.length;
    });
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    final docSnapshot = await _firestore.collection('users').doc(userId).get();
    return docSnapshot.data() ??
        {'username': 'Unknown', 'avatarColor': '000000'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド申請'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            _getPendingRequestsCount(); // 戻った際にリクエスト数を更新
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(25.0, 10, 25.0, 0.0),
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: "ユーザー名",
                  hintText: "ユーザー名を入力してください",
                  prefixIcon: Icon(Icons.person),
                  fillColor: Colors.orange[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                onPressed: _sendFriendRequest,
                child: Text(
                  'フレンド申請を送信',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 100.0),
            ElevatedButton.icon(
              icon: Icon(
                Icons.pending_actions,
                color: Colors.white,
                size: 24.0,
              ),
              label: Text(
                'フレンド承認待ち',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PendingRequestsScreen(userId: widget.userId),
                  ),
                );
                _getPendingRequestsCount(); // 承認待ち画面から戻った際にリクエスト数を更新
              },
            ),
            if (pendingRequestsCount > 0)
              Container(
                margin: EdgeInsets.only(top: 8.0),
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '$pendingRequestsCount件',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
