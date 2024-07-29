import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingRequestsScreen extends StatefulWidget {
  final String userId;

  PendingRequestsScreen({required this.userId});

  @override
  _PendingRequestsScreenState createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> requests = [];

  Future<void> _acceptRequest(String requestId, String fromUserId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'accepted',
    });

    await _firestore.collection('users').doc(widget.userId).update({
      'friends': FieldValue.arrayUnion([fromUserId]),
    });

    await _firestore.collection('users').doc(fromUserId).update({
      'friends': FieldValue.arrayUnion([widget.userId]),
    });

    await _removePendingRequests(fromUserId);
  }

  Future<void> _rejectRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'rejected',
    });

    await _removePendingRequests(requestId);
  }

  Future<void> _removePendingRequests(String fromUserId) async {
    var batch = _firestore.batch();
    var querySnapshot = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: fromUserId)
        .where('to', isEqualTo: widget.userId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    setState(() {
      requests.removeWhere((request) => request['from'] == fromUserId);
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
        title: Text('フレンド承認待ち'),
        backgroundColor: Colors.orange,
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
            .where('to', isEqualTo: widget.userId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          requests = snapshot.data!.docs;
          // 重複するフレンド申請を排除
          Map<String, DocumentSnapshot> uniqueRequests = {};
          for (var request in requests) {
            uniqueRequests[request['from']] = request;
          }
          requests = uniqueRequests.values.toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final fromUserId = request['from'];
              final requestId = request.id;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserInfo(fromUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  final userInfo = snapshot.data!;
                  final username = userInfo['username'];
                  final avatarColor = userInfo['avatarColor'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(int.parse(avatarColor, radix: 16)),
                      child: Text(
                        username[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
