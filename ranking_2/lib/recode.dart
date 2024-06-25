import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  static void addRecord(String userId, String record) {
    FirebaseFirestore.instance.collection('records').doc(userId).set({
      'record': record,
      'timestamp': Timestamp.now(),
    });
  }
}
