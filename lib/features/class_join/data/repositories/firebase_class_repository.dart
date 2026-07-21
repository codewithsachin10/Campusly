import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/class_model.dart';
import '../../domain/repositories/class_repository.dart';
import '../../../timetable/domain/models/timetable_item.dart';

class FirebaseClassRepository implements ClassRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  static final Map<String, ClassModel> _memoryClasses = {};
  static List<ClassModel>? _memoryAllClasses;

  FirebaseClassRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ClassModel>> getAllClasses() async {
    if (_memoryAllClasses != null && _memoryAllClasses!.isNotEmpty) {
      _triggerBackgroundAllClassesSync();
      return _memoryAllClasses!;
    }

    try {
      // 1. Try local cache first
      try {
        final cacheSnap = await _firestore.collection('classes').get(const GetOptions(source: Source.cache));
        if (cacheSnap.docs.isNotEmpty) {
          final cachedList = _processSnapshotDocs(cacheSnap.docs);
          if (cachedList.isNotEmpty) {
            _memoryAllClasses = cachedList;
            _triggerBackgroundAllClassesSync();
            return cachedList;
          }
        }
      } catch (_) {}

      // 2. Network query with 3-second timeout
      final snapshot = await _firestore.collection('classes').get().timeout(const Duration(seconds: 3));
      if (snapshot.docs.isEmpty) {
        return await _seedInitialClasses();
      }
      final classes = _processSnapshotDocs(snapshot.docs);
      if (classes.isEmpty) {
        return await _seedInitialClasses();
      }
      _memoryAllClasses = classes;
      for (final c in classes) {
        _memoryClasses[c.code.toUpperCase()] = c;
      }
      return classes;
    } catch (e) {
      debugPrint('Error fetching classes from Firestore: $e');
      if (_memoryAllClasses != null && _memoryAllClasses!.isNotEmpty) {
        return _memoryAllClasses!;
      }
      // If offline on fresh run without cache, return seeded CSBS-B1 directly for zero downtime
      return [
        const ClassModel(
          id: 'section-b',
          code: 'CAMPUS-CSBS-B1',
          name: 'CSBS - B BATCH 1',
          section: 'SECTION B',
          department: 'CSBS',
          institution: 'Rajalakshmi Engineering College',
          enrolledCount: 60,
          scheduleSummary: 'Mon — Fri',
          academicYear: 'Academic Year 2024 • Term 2',
        ),
      ];
    }
  }

  void _triggerBackgroundAllClassesSync() {
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final snap = await _firestore.collection('classes').get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          _memoryAllClasses = _processSnapshotDocs(snap.docs);
          for (final c in _memoryAllClasses!) {
            _memoryClasses[c.code.toUpperCase()] = c;
          }
        }
      } catch (_) {}
    });
  }

  List<ClassModel> _processSnapshotDocs(List<QueryDocumentSnapshot> docs) {
    final classes = <ClassModel>[];
    for (final doc in docs) {
      final docId = doc.id;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final code = (data['code'] as String? ?? '').toUpperCase();
      if (const ['class-1', 'class-2', 'class-3', 'class-4', 'class-5'].contains(docId) ||
          const ['CAMPUS-B7K2', 'CAMPUS-A9M4', 'CAMPUS-W3Z8', 'CAMPUS-D5X1', 'CAMPUS-E2L9'].contains(code)) {
        _firestore.collection('classes').doc(docId).delete().catchError((_) {});
        continue;
      }
      if ((docId == 'section-b' || code == 'CAMPUS-CSBS-B1') && data['scheduleVersion'] != 2) {
        _firestore.collection('classes').doc(docId).update({'scheduleVersion': 2}).catchError((_) {});
        _seedScheduleForClass(docId);
      }
      classes.add(_fromFirestoreDoc(doc));
    }
    return classes;
  }

  @override
  Future<ClassModel?> getClassByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (const ['CAMPUS-B7K2', 'CAMPUS-A9M4', 'CAMPUS-W3Z8', 'CAMPUS-D5X1', 'CAMPUS-E2L9'].contains(cleanCode)) {
      return null;
    }

    if (_memoryClasses.containsKey(cleanCode)) {
      return _memoryClasses[cleanCode];
    }

    // Special instant resolution for CSBS - B BATCH 1 if offline/not yet in memory
    if (cleanCode == 'CAMPUS-CSBS-B1' || cleanCode == 'SECTION-B') {
      const csbsClass = ClassModel(
        id: 'section-b',
        code: 'CAMPUS-CSBS-B1',
        name: 'CSBS - B BATCH 1',
        section: 'SECTION B',
        department: 'CSBS',
        institution: 'Rajalakshmi Engineering College',
        enrolledCount: 60,
        scheduleSummary: 'Mon — Fri',
        academicYear: 'Academic Year 2024 • Term 2',
      );
      _memoryClasses[cleanCode] = csbsClass;
    }

    try {
      // 1. Try local cache first
      try {
        final cacheSnap = await _firestore
            .collection('classes')
            .where('code', isEqualTo: cleanCode)
            .limit(1)
            .get(const GetOptions(source: Source.cache));
        if (cacheSnap.docs.isNotEmpty) {
          final doc = cacheSnap.docs.first;
          if (!const ['class-1', 'class-2', 'class-3', 'class-4', 'class-5'].contains(doc.id)) {
            final model = _fromFirestoreDoc(doc);
            _memoryClasses[cleanCode] = model;
            return model;
          }
        }
      } catch (_) {}

      // 2. Network query with fast timeout
      final snapshot = await _firestore
          .collection('classes')
          .where('code', isEqualTo: cleanCode)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        if (const ['class-1', 'class-2', 'class-3', 'class-4', 'class-5'].contains(doc.id)) {
          return null;
        }
        final model = _fromFirestoreDoc(doc);
        _memoryClasses[cleanCode] = model;
        return model;
      }

      final all = await getAllClasses();
      try {
        final found = all.firstWhere((c) => c.code.toUpperCase() == cleanCode);
        _memoryClasses[cleanCode] = found;
        return found;
      } catch (_) {
        return _memoryClasses[cleanCode];
      }
    } catch (e) {
      debugPrint('Error fetching class by code offline/timeout: $e');
      return _memoryClasses[cleanCode];
    }
  }

  @override
  Future<List<ClassModel>> searchClasses(
    String query, {
    String? department,
  }) async {
    final all = await getAllClasses();
    final cleanQuery = query.trim().toLowerCase();

    return all.where((c) {
      final matchesQuery =
          cleanQuery.isEmpty ||
          c.name.toLowerCase().contains(cleanQuery) ||
          c.code.toLowerCase().contains(cleanQuery) ||
          c.department.toLowerCase().contains(cleanQuery) ||
          c.institution.toLowerCase().contains(cleanQuery);

      final matchesDept =
          department == null ||
          department.isEmpty ||
          department == 'All' ||
          c.department.toUpperCase() == department.toUpperCase();

      return matchesQuery && matchesDept;
    }).toList();
  }

  @override
  Future<ClassModel> createClass({
    required String name,
    required String section,
    required String department,
    required String institution,
    required String scheduleSummary,
  }) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomPart = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    final code = 'CAMPUS-$randomPart';
    final id = _uuid.v4();

    final formattedSection = section.toUpperCase().startsWith('SECTION')
        ? section.toUpperCase()
        : 'SECTION ${section.toUpperCase()}';

    final newClass = ClassModel(
      id: id,
      code: code,
      name: name,
      section: formattedSection,
      department: department,
      institution: institution,
      enrolledCount: 1,
      scheduleSummary: scheduleSummary,
      creatorId: FirebaseAuth.instance.currentUser?.uid,
    );

    // Save to Firestore
    try {
      await _firestore.collection('classes').doc(id).set(newClass.toJson());
      await _seedScheduleForClass(id);
    } catch (e) {
      debugPrint('Error saving created class to Firestore: $e');
    }

    return newClass;
  }

  ClassModel _fromFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClassModel(
      id: doc.id,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Class',
      section: data['section'] as String? ?? '',
      department: data['department'] as String? ?? 'General',
      institution: data['institution'] as String? ?? 'College',
      enrolledCount: (data['enrolledCount'] as num?)?.toInt() ?? 1,
      scheduleSummary: data['scheduleSummary'] as String? ?? '',
      academicYear:
          data['academicYear'] as String? ?? 'Academic Year 2024 • Term 2',
      creatorId: data['creatorId'] as String?,
    );
  }

  Future<List<ClassModel>> _seedInitialClasses() async {
    final initial = [
      const ClassModel(
        id: 'section-b',
        code: 'CAMPUS-CSBS-B1',
        name: 'CSBS - B BATCH 1',
        section: 'SECTION B',
        department: 'CSBS',
        institution: 'Rajalakshmi Engineering College',
        enrolledCount: 60,
        scheduleSummary: 'Mon — Fri',
        academicYear: 'Academic Year 2024 • Term 2',
      ),
    ];

    for (final c in initial) {
      try {
        final data = c.toJson()..['scheduleVersion'] = 2;
        await _firestore.collection('classes').doc(c.id).set(data);
        await _seedScheduleForClass(c.id);
      } catch (e) {
        debugPrint('Error seeding initial class: $e');
      }
    }

    return initial;
  }

  Future<void> _seedScheduleForClass(String classId) async {
    final scheduleCollection = _firestore
        .collection('classes')
        .doc(classId)
        .collection('schedule');
    
    final List<TimetableItem> items =
        (classId == 'section-b' || classId == 'CAMPUS-CSBS-B1')
            ? _getCsbsSectionBSchedule()
            : [];

    if (items.isNotEmpty) {
      try {
        final existing = await scheduleCollection.get();
        for (final doc in existing.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error clearing existing schedule items: $e');
      }
    }

    for (final item in items) {
      try {
        await scheduleCollection.doc(item.id).set(item.toJson());
      } catch (e) {
        debugPrint('Error seeding schedule item: $e');
      }
    }
  }

  List<TimetableItem> _getCsbsSectionBSchedule() {
    return [
      // MONDAY
      const TimetableItem(
        id: 'mon_0800_0940',
        title: 'Object Oriented Programming using Java',
        shortTitle: 'OOP using Java',
        subjectCode: 'CS23333',
        dayOfWeek: 'mon',
        startTime: '08:00 AM',
        endTime: '09:40 AM',
        startHour: 8,
        startMinute: 0,
        endHour: 9,
        endMinute: 40,
        category: 'Lecture',
        room: 'ANEW101-A',
        instructor: 'Jayanthi M',
      ),
      const TimetableItem(
        id: 'mon_1000_1140',
        title: 'Object Oriented Programming using Java',
        shortTitle: 'OOP using Java',
        subjectCode: 'CS23333',
        dayOfWeek: 'mon',
        startTime: '10:00 AM',
        endTime: '11:40 AM',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 40,
        category: 'Lecture',
        room: 'ANEW101-A',
        instructor: 'Jayanthi M',
      ),
      const TimetableItem(
        id: 'mon_1300_1450',
        title: 'Database Technology',
        shortTitle: 'DB Tech',
        subjectCode: 'CB23333',
        dayOfWeek: 'mon',
        startTime: '01:00 PM',
        endTime: '02:50 PM',
        startHour: 13,
        startMinute: 0,
        endHour: 14,
        endMinute: 50,
        category: 'Lab',
        room: 'KS02-A',
        instructor: 'Rajammal K',
      ),
      const TimetableItem(
        id: 'mon_1500_1640',
        title: 'Database Technology',
        shortTitle: 'DB Tech',
        subjectCode: 'CB23333',
        dayOfWeek: 'mon',
        startTime: '03:00 PM',
        endTime: '04:40 PM',
        startHour: 15,
        startMinute: 0,
        endHour: 16,
        endMinute: 40,
        category: 'Lab',
        room: 'KS02-A',
        instructor: 'Rajammal K',
      ),

      // TUESDAY
      const TimetableItem(
        id: 'tue_0800_0825',
        title: 'Computer Organization and Architecture',
        shortTitle: 'COA',
        subjectCode: 'CB23312',
        dayOfWeek: 'tue',
        startTime: '08:00 AM',
        endTime: '08:25 AM',
        startHour: 8,
        startMinute: 0,
        endHour: 8,
        endMinute: 25,
        category: 'Lecture',
        room: 'B424',
        instructor: 'Nandha Kumar P',
        sharedSlot: true,
        sharedSlotGroup: 'tue_0800_0850',
      ),
      const TimetableItem(
        id: 'tue_0825_0850',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'tue',
        startTime: '08:25 AM',
        endTime: '08:50 AM',
        startHour: 8,
        startMinute: 25,
        endHour: 8,
        endMinute: 50,
        category: 'Lecture',
        room: 'B424',
        instructor: 'Manikandan Thirumalaisamy',
        sharedSlot: true,
        sharedSlotGroup: 'tue_0800_0850',
      ),
      const TimetableItem(
        id: 'tue_0900_0950',
        title: 'Formal Language and Automata Theory',
        shortTitle: 'FLAT',
        subjectCode: 'CB23311',
        dayOfWeek: 'tue',
        startTime: '09:00 AM',
        endTime: '09:50 AM',
        startHour: 9,
        startMinute: 0,
        endHour: 9,
        endMinute: 50,
        category: 'Lecture',
        room: 'B411',
        instructor: 'Vishnu Kumar A',
      ),
      const TimetableItem(
        id: 'tue_1000_1140',
        title: 'Database Technology',
        shortTitle: 'DB Tech',
        subjectCode: 'CB23333',
        dayOfWeek: 'tue',
        startTime: '10:00 AM',
        endTime: '11:40 AM',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 40,
        category: 'Lab',
        room: 'KS02-A',
        instructor: 'Rajammal K',
      ),
      const TimetableItem(
        id: 'tue_1300_1325',
        title: 'Computer Organization and Architecture',
        shortTitle: 'COA',
        subjectCode: 'CB23312',
        dayOfWeek: 'tue',
        startTime: '01:00 PM',
        endTime: '01:25 PM',
        startHour: 13,
        startMinute: 0,
        endHour: 13,
        endMinute: 25,
        category: 'Lecture',
        room: 'A309',
        instructor: 'Nandha Kumar P',
        sharedSlot: true,
        sharedSlotGroup: 'tue_1300_1350',
      ),
      const TimetableItem(
        id: 'tue_1325_1350',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'tue',
        startTime: '01:25 PM',
        endTime: '01:50 PM',
        startHour: 13,
        startMinute: 25,
        endHour: 13,
        endMinute: 50,
        category: 'Lecture',
        room: 'A309',
        instructor: 'Manikandan Thirumalaisamy',
        sharedSlot: true,
        sharedSlotGroup: 'tue_1300_1350',
      ),
      const TimetableItem(
        id: 'tue_1400_1425',
        title: 'Environmental Sciences',
        shortTitle: 'Env Sci',
        subjectCode: 'MC23313',
        dayOfWeek: 'tue',
        startTime: '02:00 PM',
        endTime: '02:25 PM',
        startHour: 14,
        startMinute: 0,
        endHour: 14,
        endMinute: 25,
        category: 'Lecture',
        room: 'B416',
        instructor: 'J Edward Jeyakumar',
        sharedSlot: true,
        sharedSlotGroup: 'tue_1400_1450',
      ),
      const TimetableItem(
        id: 'tue_1425_1450',
        title: 'Formal Language and Automata Theory',
        shortTitle: 'FLAT',
        subjectCode: 'CB23311',
        dayOfWeek: 'tue',
        startTime: '02:25 PM',
        endTime: '02:50 PM',
        startHour: 14,
        startMinute: 25,
        endHour: 14,
        endMinute: 50,
        category: 'Lecture',
        room: 'B416',
        instructor: 'Vishnu Kumar A',
        sharedSlot: true,
        sharedSlotGroup: 'tue_1400_1450',
      ),

      // WEDNESDAY
      const TimetableItem(
        id: 'wed_0800_0940',
        title: 'Database Technology',
        shortTitle: 'DB Tech',
        subjectCode: 'CB23333',
        dayOfWeek: 'wed',
        startTime: '08:00 AM',
        endTime: '09:40 AM',
        startHour: 8,
        startMinute: 0,
        endHour: 9,
        endMinute: 40,
        category: 'Lab',
        room: 'KS02-A',
        instructor: 'Rajammal K',
      ),
      const TimetableItem(
        id: 'wed_1100_1125',
        title: 'Computer Organization and Architecture',
        shortTitle: 'COA',
        subjectCode: 'CB23312',
        dayOfWeek: 'wed',
        startTime: '11:00 AM',
        endTime: '11:25 AM',
        startHour: 11,
        startMinute: 0,
        endHour: 11,
        endMinute: 25,
        category: 'Lecture',
        room: 'B423',
        instructor: 'Nandha Kumar P',
        sharedSlot: true,
        sharedSlotGroup: 'wed_1100_1150',
      ),
      const TimetableItem(
        id: 'wed_1125_1150',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'wed',
        startTime: '11:25 AM',
        endTime: '11:50 AM',
        startHour: 11,
        startMinute: 25,
        endHour: 11,
        endMinute: 50,
        category: 'Lecture',
        room: 'B423',
        instructor: 'Manikandan Thirumalaisamy',
        sharedSlot: true,
        sharedSlotGroup: 'wed_1100_1150',
      ),
      const TimetableItem(
        id: 'wed_1300_1450',
        title: 'Object Oriented Programming using Java',
        shortTitle: 'OOP using Java',
        subjectCode: 'CS23333',
        dayOfWeek: 'wed',
        startTime: '01:00 PM',
        endTime: '02:50 PM',
        startHour: 13,
        startMinute: 0,
        endHour: 14,
        endMinute: 50,
        category: 'Lecture',
        room: 'ANEW101-B',
        instructor: 'Jayanthi M',
      ),
      const TimetableItem(
        id: 'wed_1500_1550',
        title: 'Formal Language and Automata Theory',
        shortTitle: 'FLAT',
        subjectCode: 'CB23311',
        dayOfWeek: 'wed',
        startTime: '03:00 PM',
        endTime: '03:50 PM',
        startHour: 15,
        startMinute: 0,
        endHour: 15,
        endMinute: 50,
        category: 'Lecture',
        room: 'A311',
        instructor: 'Vishnu Kumar A',
      ),

      // THURSDAY
      const TimetableItem(
        id: 'thu_0800_0940',
        title: 'Object Oriented Programming using Java',
        shortTitle: 'OOP using Java',
        subjectCode: 'CS23333',
        dayOfWeek: 'thu',
        startTime: '08:00 AM',
        endTime: '09:40 AM',
        startHour: 8,
        startMinute: 0,
        endHour: 9,
        endMinute: 40,
        category: 'Lecture',
        room: 'ANEW101-A',
        instructor: 'Jayanthi M',
      ),
      const TimetableItem(
        id: 'thu_1100_1125',
        title: 'Environmental Sciences',
        shortTitle: 'Env Sci',
        subjectCode: 'MC23313',
        dayOfWeek: 'thu',
        startTime: '11:00 AM',
        endTime: '11:25 AM',
        startHour: 11,
        startMinute: 0,
        endHour: 11,
        endMinute: 25,
        category: 'Lecture',
        room: 'A311',
        instructor: 'J Edward Jeyakumar',
        sharedSlot: true,
        sharedSlotGroup: 'thu_1100_1150',
      ),
      const TimetableItem(
        id: 'thu_1125_1150',
        title: 'Formal Language and Automata Theory',
        shortTitle: 'FLAT',
        subjectCode: 'CB23311',
        dayOfWeek: 'thu',
        startTime: '11:25 AM',
        endTime: '11:50 AM',
        startHour: 11,
        startMinute: 25,
        endHour: 11,
        endMinute: 50,
        category: 'Lecture',
        room: 'A311',
        instructor: 'Vishnu Kumar A',
        sharedSlot: true,
        sharedSlotGroup: 'thu_1100_1150',
      ),
      const TimetableItem(
        id: 'thu_1300_1325',
        title: 'Computer Organization and Architecture',
        shortTitle: 'COA',
        subjectCode: 'CB23312',
        dayOfWeek: 'thu',
        startTime: '01:00 PM',
        endTime: '01:25 PM',
        startHour: 13,
        startMinute: 0,
        endHour: 13,
        endMinute: 25,
        category: 'Lecture',
        room: 'B210',
        instructor: 'Nandha Kumar P',
        sharedSlot: true,
        sharedSlotGroup: 'thu_1300_1350',
      ),
      const TimetableItem(
        id: 'thu_1325_1350',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'thu',
        startTime: '01:25 PM',
        endTime: '01:50 PM',
        startHour: 13,
        startMinute: 25,
        endHour: 13,
        endMinute: 50,
        category: 'Lecture',
        room: 'B210',
        instructor: 'Manikandan Thirumalaisamy',
        sharedSlot: true,
        sharedSlotGroup: 'thu_1300_1350',
      ),
      const TimetableItem(
        id: 'thu_1400_1425',
        title: 'Computer Organization and Architecture',
        shortTitle: 'COA',
        subjectCode: 'CB23312',
        dayOfWeek: 'thu',
        startTime: '02:00 PM',
        endTime: '02:25 PM',
        startHour: 14,
        startMinute: 0,
        endHour: 14,
        endMinute: 25,
        category: 'Lecture',
        room: 'B404',
        instructor: 'Nandha Kumar P',
        sharedSlot: true,
        sharedSlotGroup: 'thu_1400_1450',
      ),
      const TimetableItem(
        id: 'thu_1425_1450',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'thu',
        startTime: '02:25 PM',
        endTime: '02:50 PM',
        startHour: 14,
        startMinute: 25,
        endHour: 14,
        endMinute: 50,
        category: 'Lecture',
        room: 'B404',
        instructor: 'Manikandan Thirumalaisamy',
        sharedSlot: true,
        sharedSlotGroup: 'thu_1400_1450',
      ),
      const TimetableItem(
        id: 'thu_1500_1550',
        title: 'Computational Statistics',
        shortTitle: 'Comp Stats',
        subjectCode: 'CB23331',
        dayOfWeek: 'thu',
        startTime: '03:00 PM',
        endTime: '03:50 PM',
        startHour: 15,
        startMinute: 0,
        endHour: 15,
        endMinute: 50,
        category: 'Lecture',
        room: 'A310',
        instructor: 'Sophia M',
      ),
      const TimetableItem(
        id: 'thu_1600_1650',
        title: 'Computational Statistics',
        shortTitle: 'Comp Stats',
        subjectCode: 'CB23331',
        dayOfWeek: 'thu',
        startTime: '04:00 PM',
        endTime: '04:50 PM',
        startHour: 16,
        startMinute: 0,
        endHour: 16,
        endMinute: 50,
        category: 'Lecture',
        room: 'A311',
        instructor: 'Sophia M',
      ),

      // FRIDAY
      const TimetableItem(
        id: 'fri_0800_0940',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'fri',
        startTime: '08:00 AM',
        endTime: '09:40 AM',
        startHour: 8,
        startMinute: 0,
        endHour: 9,
        endMinute: 40,
        category: 'Lab',
        room: 'JL3',
        instructor: 'Manikandan Thirumalaisamy',
      ),
      const TimetableItem(
        id: 'fri_1000_1140',
        title: 'Computational Statistics',
        shortTitle: 'Comp Stats',
        subjectCode: 'CB23331',
        dayOfWeek: 'fri',
        startTime: '10:00 AM',
        endTime: '11:40 AM',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 40,
        category: 'Lab',
        room: 'JL2',
        instructor: 'Sophia M',
      ),
      const TimetableItem(
        id: 'fri_1300_1325',
        title: 'Computer Organization and Architecture',
        shortTitle: 'COA',
        subjectCode: 'CB23312',
        dayOfWeek: 'fri',
        startTime: '01:00 PM',
        endTime: '01:25 PM',
        startHour: 13,
        startMinute: 0,
        endHour: 13,
        endMinute: 25,
        category: 'Lecture',
        room: 'A303',
        instructor: 'Nandha Kumar P',
        sharedSlot: true,
        sharedSlotGroup: 'fri_1300_1350',
      ),
      const TimetableItem(
        id: 'fri_1325_1350',
        title: 'Software Engineering',
        shortTitle: 'SE',
        subjectCode: 'CB23332',
        dayOfWeek: 'fri',
        startTime: '01:25 PM',
        endTime: '01:50 PM',
        startHour: 13,
        startMinute: 25,
        endHour: 13,
        endMinute: 50,
        category: 'Lecture',
        room: 'A303',
        instructor: 'Manikandan Thirumalaisamy',
        sharedSlot: true,
        sharedSlotGroup: 'fri_1300_1350',
      ),
      const TimetableItem(
        id: 'fri_1400_1450',
        title: 'Computational Statistics',
        shortTitle: 'Comp Stats',
        subjectCode: 'CB23331',
        dayOfWeek: 'fri',
        startTime: '02:00 PM',
        endTime: '02:50 PM',
        startHour: 14,
        startMinute: 0,
        endHour: 14,
        endMinute: 50,
        category: 'Lecture',
        room: 'B322',
        instructor: 'Sophia M',
      ),
    ];
  }
}
