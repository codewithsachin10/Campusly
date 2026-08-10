import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/curriculum_item.dart';
import '../../domain/models/curriculum_data.dart';

class CurriculumRepository {
  final SupabaseClient _supabase;

  CurriculumRepository(this._supabase);

  Future<CurriculumData?> getCurriculumBySemester(int semester) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Fetch the student's department profile
      final studentData = await _supabase
          .from('students')
          .select('departmentId')
          .eq('id', user.id)
          .maybeSingle();

      String? department;
      if (studentData != null && studentData['departmentId'] != null) {
        department = studentData['departmentId'].toString();
      }

      if (department == null || department.isEmpty) {
        throw Exception('Student department is missing.');
      }

      String departmentUuid = department;

      // Check if it's a UUID format. If not, it's probably a string code (like "CSBS").
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(department);
      
      if (!isUuid) {
        // 1. Convert string department code (e.g. "CSBS") to UUID department_id
        final deptResponse = await _supabase
            .from('departments')
            .select('id')
            .eq('code', department)
            .limit(1)
            .maybeSingle();

        if (deptResponse == null) {
          throw Exception('No department found in "departments" table with code: $department');
        }
        departmentUuid = deptResponse['id'];
      }

      // 1. Find out the string 'code' of the student's current department UUID
      final studentDeptResponse = await _supabase
          .from('departments')
          .select('code')
          .eq('id', departmentUuid)
          .maybeSingle();
          
      String? targetCode;
      if (studentDeptResponse != null) {
        targetCode = studentDeptResponse['code'];
      }

      // 2. Fetch ANY regulation where the department has the SAME string code
      var regResponse = await _supabase
          .from('academic_regulations')
          .select('id, departments!inner(code)')
          .eq('departments.code', targetCode ?? 'UNKNOWN')
          .limit(1)
          .maybeSingle();

      if (regResponse == null) {
        // Ultimate fallback just to show something if literally nothing matches
        regResponse = await _supabase
            .from('academic_regulations')
            .select('id')
            .limit(1)
            .maybeSingle();
            
        if (regResponse == null) return null;
      }
      final regulationId = regResponse['id'];

      // 3. Get the specific semester ID for this regulation
      final semResponse = await _supabase
          .from('academic_semesters')
          .select('id')
          .eq('regulation_id', regulationId)
          .eq('semester_number', semester)
          .limit(1)
          .maybeSingle();

      if (semResponse == null) {
        return null;
      }
      final semesterId = semResponse['id'];

      // 4. Get the subjects for this semester
      final subjectsResponse = await _supabase
          .from('curriculum_subjects')
          .select('*')
          .eq('semester_id', semesterId)
          .order('subject_code'); // Assuming 'subject_code' is the column name based on my probe
          
      // Map the data
      final data = subjectsResponse.map((row) {
        row['semester'] = semester;
        return CurriculumItem.fromMap(row);
      }).toList();
      
      // Get department name and regulation details
      String deptName = 'Department';
      String batch = '2024-2028';
      
      try {
        final deptDetails = await _supabase
            .from('departments')
            .select('name')
            .eq('code', targetCode ?? '')
            .limit(1)
            .maybeSingle();
        if (deptDetails != null && deptDetails['name'] != null) {
          deptName = deptDetails['name'];
        }
        
        final regDetails = await _supabase
            .from('academic_regulations')
            .select('year, batch')
            .eq('id', regulationId)
            .maybeSingle();
        if (regDetails != null) {
          batch = regDetails['batch'] ?? '2024-2028';
        }
      } catch (_) {}

      return CurriculumData(
        subjects: data,
        departmentName: deptName,
        batchName: batch,
        currentSemester: semester,
      );
    } catch (e) {
      print('Failed to load curriculum from DB: $e');
      return null;
    }
  }
}
