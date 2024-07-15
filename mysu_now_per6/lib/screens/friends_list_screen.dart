import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'friend_request_screen.dart';

class FriendsListScreen extends StatelessWidget {
  final String userId;

  FriendsListScreen({required this.userId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _removeFriend(String friendId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayRemove([friendId]),
    });
    await _firestore.collection('users').doc(friendId).update({
      'friends': FieldValue.arrayRemove([userId]),
    });
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    final docSnapshot = await _firestore.collection('users').doc(userId).get();
    return docSnapshot.data() ??
        {'username': 'Unknown', 'avatarColor': '000000'};
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String friendId, String username) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('フレンド削除確認'),
          content: Text('$usernameをフレンドから削除しますか？'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('削除'),
              onPressed: () {
                _removeFriend(friendId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('フレンド一覧'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final friends = List<String>.from(userData['friends']);

          if (userData == null || !userData.containsKey('friends')) {
            return Center(child: Text('フレンドがいません'));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendId = friends[index];

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserInfo(friendId),
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
                      child: Text(
                        username[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      username,
                      style: TextStyle(fontSize: 22.0), // ここで名前のサイズを変更
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _showDeleteConfirmationDialog(
                          context, friendId, username),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 370.0,
              height: 65,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 40.0,
                ),
                label: Text(
                  'フレンドを追加する',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // 修正点：backgroundColor を使用
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendRequestScreen(userId: userId),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
