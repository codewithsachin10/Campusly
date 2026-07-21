import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/faculty_model.dart';

class FacultyRepository {
  final FirebaseFirestore _firestore;
  static final Map<String, FacultyModel> _memoryCache = {};
  static bool _seeded = false;

  FacultyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const List<FacultyModel> _seedProfiles = [
    FacultyModel(
      id: 'faculty_rajammal',
      name: 'Rajammal K',
      subjectCode: 'CB23333',
      subjectName: 'Database Technology',
      officeRoom: 'CSBS Staff Room — Academic Block C, Room 304',
      contactNumber: '+91 98402 11234',
      email: 'rajammal.k@rajalakshmi.edu.in',
    ),
    FacultyModel(
      id: 'faculty_sophia',
      name: 'Sophia M',
      subjectCode: 'CB23331',
      subjectName: 'Computational Statistics',
      officeRoom: 'Maths & CSBS Wing — Academic Block B, Room 212',
      contactNumber: '+91 97890 44512',
      email: 'sophia.m@rajalakshmi.edu.in',
    ),
    FacultyModel(
      id: 'faculty_vishnu',
      name: 'Vishnu Kumar A',
      subjectCode: 'CB23311',
      subjectName: 'Formal Language and Automata Theory',
      officeRoom: 'CSBS Department Staff Block — Room 308',
      contactNumber: '+91 99401 88321',
      email: 'vishnukumar.a@rajalakshmi.edu.in',
    ),
    FacultyModel(
      id: 'faculty_manikandan',
      name: 'Manikandan Thirumalaisamy',
      subjectCode: 'CB23332',
      subjectName: 'Software Engineering',
      officeRoom: 'CSBS Department Head Office — Room 301',
      contactNumber: '+91 94441 55678',
      email: 'manikandan.t@rajalakshmi.edu.in',
    ),
    FacultyModel(
      id: 'faculty_edward',
      name: 'J Edward Jeyakumar',
      subjectCode: 'MC23313',
      subjectName: 'Environmental Sciences',
      officeRoom: 'Humanities & Sciences Wing — Room 104',
      contactNumber: '+91 98845 22910',
      email: 'edwardjeyakumar.j@rajalakshmi.edu.in',
    ),
    FacultyModel(
      id: 'faculty_nandha',
      name: 'Nandha Kumar P',
      subjectCode: 'CB23312',
      subjectName: 'Computer Organization and Architecture',
      officeRoom: 'Hardware & Architecture Lab — Room 205',
      contactNumber: '+91 96001 33490',
      email: 'nandhakumar.p@rajalakshmi.edu.in',
    ),
    FacultyModel(
      id: 'faculty_jayanthi',
      name: 'Jayanthi M',
      subjectCode: 'CS23333',
      subjectName: 'Object Oriented Programming using Java',
      officeRoom: 'CSBS Staff Room — Academic Block C, Room 305',
      contactNumber: '+91 98412 66781',
      email: 'jayanthi.m@rajalakshmi.edu.in',
    ),
  ];

  Future<void> seedFacultiesIfNeeded() async {
    if (_seeded) return;
    _seeded = true;
    for (final f in _seedProfiles) {
      _memoryCache[f.name.toLowerCase()] = f;
      _memoryCache[f.subjectCode.toUpperCase()] = f;
    }
    try {
      final snap = await _firestore
          .collection('faculties')
          .doc('v1')
          .collection('items')
          .get(const GetOptions(source: Source.cache));
      if (snap.docs.isEmpty) {
        for (final f in _seedProfiles) {
          _firestore
              .collection('faculties')
              .doc('v1')
              .collection('items')
              .doc(f.id)
              .set(f.toJson(), SetOptions(merge: true))
              .catchError((_) {});
        }
      }
    } catch (_) {}
  }

  Future<FacultyModel?> getFacultyProfile(String nameOrSubjectCode) async {
    await seedFacultiesIfNeeded();
    final clean = nameOrSubjectCode.trim().toLowerCase();
    final cleanCode = nameOrSubjectCode.trim().toUpperCase();

    if (_memoryCache.containsKey(clean)) return _memoryCache[clean];
    if (_memoryCache.containsKey(cleanCode)) return _memoryCache[cleanCode];

    // Partial name lookup
    for (final f in _seedProfiles) {
      if (f.name.toLowerCase().contains(clean) || clean.contains(f.name.toLowerCase())) {
        return f;
      }
      if (f.subjectCode.toUpperCase() == cleanCode) {
        return f;
      }
    }

    try {
      final snap = await _firestore
          .collection('faculties')
          .doc('v1')
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 3));
      for (final doc in snap.docs) {
        final f = FacultyModel.fromJson(doc.data());
        _memoryCache[f.name.toLowerCase()] = f;
        _memoryCache[f.subjectCode.toUpperCase()] = f;
        if (f.name.toLowerCase().contains(clean) || f.subjectCode.toUpperCase() == cleanCode) {
          return f;
        }
      }
    } catch (_) {}

    return null;
  }
}
