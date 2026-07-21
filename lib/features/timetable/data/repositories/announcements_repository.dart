import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/announcement_model.dart';

class AnnouncementsRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  AnnouncementsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .doc('v1')
        .collection('sections')
        .doc('section-b')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AnnouncementModel.fromJson(doc.data())).toList())
        .handleError((e) {
          debugPrint('Announcements stream offline/error: $e');
        });
  }

  Future<AnnouncementModel> postAnnouncement({
    required String title,
    required String message,
    String priority = 'normal',
    String author = 'Admin / CR',
  }) async {
    final id = _uuid.v4();
    final model = AnnouncementModel(
      id: id,
      title: title,
      message: message,
      author: author,
      createdAt: DateTime.now(),
      priority: priority,
    );

    await _firestore
        .collection('announcements')
        .doc('v1')
        .collection('sections')
        .doc('section-b')
        .collection('items')
        .doc(id)
        .set(model.toJson(), SetOptions(merge: true));
    return model;
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore
        .collection('announcements')
        .doc('v1')
        .collection('sections')
        .doc('section-b')
        .collection('items')
        .doc(id)
        .delete();
  }
}
