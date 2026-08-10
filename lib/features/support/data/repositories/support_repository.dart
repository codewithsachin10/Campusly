import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_ticket.dart';
import '../models/support_message.dart';

class SupportRepository {
  final SupabaseClient _supabase;

  SupportRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // Tickets
  Future<List<SupportTicket>> getMyTickets() async {
    final response = await _supabase
        .from('support_tickets')
        .select('*, students(*)')
        .eq('student_id', _currentUserId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => SupportTicket.fromJson(json)).toList();
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required String priority,
    String? categoryId,
    String? appVersion,
    String? osVersion,
    String? platform,
    String? currentScreen,
  }) async {
    final finalSubject = categoryId != null ? '[$categoryId] $subject' : subject;
    final ticketNumber = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${(1000 + (DateTime.now().microsecond % 9000)).toString()}';

    // Auto-heal missing student profile for test accounts
    try {
      final studentCheck = await _supabase.from('students').select('id').eq('id', _currentUserId).maybeSingle();
      if (studentCheck == null) {
        final email = _supabase.auth.currentUser!.email ?? 'test@rajalakshmi.edu.in';
        await _supabase.from('students').insert({
          'id': _currentUserId,
          'name': 'Test Student',
          'email': email,
          'rollNumber': 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
          // Providing dummy values for constraints that might exist
          'departmentId': 'CSE',
          'section': 'A',
          'academicYear': '2025-2026',
        });
      }
    } catch (e) {
      print('Auto-heal failed: $e');
      // If it still fails, the ticket insertion will throw the FK error
    }

    final response = await _supabase.from('support_tickets').insert({
      'student_id': _currentUserId,
      'ticket_number': ticketNumber,
      'subject': finalSubject,
      'description': description,
      'priority': priority,
      'category_id': null, // Need actual UUID from support_categories
      'app_version': appVersion,
      'os_version': osVersion,
      'platform': platform,
      'current_screen': currentScreen,
    }).select().single();

    return SupportTicket.fromJson(response);
  }

  // Messages
  Future<List<SupportMessage>> getMessages(String ticketId) async {
    final response = await _supabase
        .from('support_ticket_messages')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => SupportMessage.fromJson(json)).toList();
  }

  Future<SupportMessage> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final response = await _supabase.from('support_ticket_messages').insert({
      'ticket_id': ticketId,
      'sender_id': _currentUserId,
      'sender_type': 'Student',
      'message': message,
      'is_internal': false,
    }).select().single();

    return SupportMessage.fromJson(response);
  }

  // Realtime
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String ticketId) {
    return _supabase
        .from('support_ticket_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
  }

  // FAQs
  Future<List<Map<String, dynamic>>> getFAQs() async {
    final response = await _supabase
        .from('support_faqs')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: true);
        
    return List<Map<String, dynamic>>.from(response);
  }
}
