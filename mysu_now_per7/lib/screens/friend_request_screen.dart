import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  String _infoText = '';
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _getPendingRequestsCount();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _sendFriendRequest() async {
    await _checkConnectivity();
    if (!_isConnected) {
      setState(() {
        _infoText = "インターネット接続がありません。接続を確認してください。";
      });
      return;
    }

    String friendUsername = _controller.text;
    if (friendUsername.isEmpty) {
      setState(() {
        _infoText = "ユーザー名を入力してください。";
      });
      return;
    }

    QuerySnapshot query = await _firestore
        .collection('users')
        .where('username', isEqualTo: friendUsername)
        .get();

    if (query.docs.isEmpty) {
      setState(() {
        _infoText = 'ユーザが見つかりませんでした';
      });
      return;
    }

    String friendId = query.docs.first.id;

    // フレンドかどうかの確認
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userId).get();
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    List friends = userData?['friends'] ?? [];
    if (friends.contains(friendId)) {
      setState(() {
        _infoText = '既にフレンドです';
      });
      return;
    }

    // フレンド申請中かどうかの確認
    QuerySnapshot existingRequest = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: widget.userId)
        .where('to', isEqualTo: friendId)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existingRequest.docs.isNotEmpty) {
      setState(() {
        _infoText = '既にフレンド申請中です';
      });
      return;
    }

    // 相手からのフレンド申請があるかどうかの確認
    QuerySnapshot reverseRequest = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: friendId)
        .where('to', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .get();
    if (reverseRequest.docs.isNotEmpty) {
      // 相手からのフレンド申請が存在する場合、両方のリクエストを承認してフレンドにする
      await _firestore
          .collection('friend_requests')
          .doc(reverseRequest.docs.first.id)
          .update({
        'status': 'accepted',
      });
      await _firestore.collection('users').doc(widget.userId).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayUnion([widget.userId]),
      });

      setState(() {
        _infoText = 'フレンドになりました';
      });

      _controller.clear();
      _getPendingRequestsCount();
      return;
    }

    await _firestore.collection('friend_requests').add({
      'from': widget.userId,
      'to': friendId,
      'status': 'pending',
    });

    setState(() {
      _infoText = 'フレンド申請を送信しました';
    });

    _controller.clear();
    _getPendingRequestsCount();
  }

  Future<void> _getPendingRequestsCount() async {
    QuerySnapshot query = await _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .get();

    // 重複するフレンド申請を排除してカウント
    Set<String> uniqueUserIds =
        query.docs.map((doc) => doc['from'] as String).toSet();
    setState(() {
      pendingRequestsCount = uniqueUserIds.length;
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
                onPressed: _isConnected
                    ? _sendFriendRequest
                    : () {
                        setState(() {
                          _infoText = "インターネット接続がありません。確認してください。";
                        });
                      },
                child: Text(
                  'フレンド申請を送信',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.orange : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (_infoText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _infoText,
                  style: TextStyle(color: Colors.red, fontSize: 16.0),
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
                    fontSize: 18.0),
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
