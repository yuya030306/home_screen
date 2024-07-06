import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'ユーザー名'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendFriendRequest,
              child: Text('フレンド申請を送信'),
            ),
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PendingRequestsScreen(userId: widget.userId),
                  ),
                );
              },
              child: Row(
                children: [
                  Text('フレンド承認待ち', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8.0),
                  if (pendingRequestsCount > 0)
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
    if (docSnapshot.exists) {
      return docSnapshot.data()?['username'] ?? 'Unknown';
    }
    return 'Unknown';
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
