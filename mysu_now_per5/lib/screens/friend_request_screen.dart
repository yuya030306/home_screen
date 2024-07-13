import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// フレンドリクエスト画面のクラス
class FriendRequestScreen extends StatefulWidget {
  final String userId;
  //required 修飾子を使用して、コンストラクタの呼び出し時にこのフィールドが必須であることを示す
  FriendRequestScreen({required this.userId});

  @override
  _FriendRequestScreenState createState() => _FriendRequestScreenState();
}

// フレンドリクエスト画面の状態管理クラス
class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _controller = TextEditingController();
  int pendingRequestsCount = 0; //承認待ちのフレンドリクエストの数

  @override
  void initState() {
    super.initState();
    //これにより、ウィジェットの初期化時に承認待ちのフレンドリクエスト数を取得し、表示の更新を行うことができる
    _getPendingRequestsCount(); // 承認待ちのフレンドリクエスト数を取得する
  }

  // フレンドリクエストを送信するメソッド
  Future<void> _sendFriendRequest() async {
    String friendUsername = _controller.text;
    if (friendUsername.isEmpty) return;

    // ユーザー名で検索
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド申請'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            SizedBox(
              width: 250, // 幅を親ウィジェットの幅に合わせる
              height: 50, // 高さを指定
              child: ElevatedButton(
                onPressed: _sendFriendRequest,
                child: Text(
                  'フレンド申請を送信',
                  style: TextStyle(
                    fontSize: 18, // 文字サイズを大きく
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
                backgroundColor: Colors.green, // ボタンの背景色を緑に設定
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PendingRequestsScreen(userId: widget.userId),
                  ),
                );
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

class PendingRequestsScreen extends StatelessWidget {
  final String userId;

  PendingRequestsScreen({required this.userId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _acceptRequest(String requestId, String fromUserId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'accepted',
    });

    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayUnion([fromUserId]),
    });

    await _firestore.collection('users').doc(fromUserId).update({
      'friends': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> _rejectRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Future<String> _getUsername(String userId) async {
    final docSnapshot = await _firestore.collection('users').doc(userId).get();
    return docSnapshot.data()?['username'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド承認待ち'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('friend_requests')
            .where('to', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final fromUserId = request['from'];
              final requestId = request.id;

              return FutureBuilder<String>(
                future: _getUsername(fromUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  final username = snapshot.data!;
                  return ListTile(
                    title: Text(username),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () =>
                              _acceptRequest(requestId, fromUserId),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => _rejectRequest(requestId),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
