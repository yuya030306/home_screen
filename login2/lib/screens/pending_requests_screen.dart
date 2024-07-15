import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingRequestsScreen extends StatelessWidget {
  final String userId;

  PendingRequestsScreen({required this.userId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _acceptRequest(String requestId, String fromId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'accepted',
    });
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayUnion([fromId]),
    });
    await _firestore.collection('users').doc(fromId).update({
      'friends': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> _rejectRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
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
              final fromId = request['from'];
              final requestId = request.id;

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserInfo(fromId),
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
                      backgroundColor: Color(int.parse('0x$avatarColor')),
                    ),
                    title: Text(username),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () => _acceptRequest(requestId, fromId),
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
