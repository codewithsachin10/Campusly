import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/connection_model.dart';
import '../../auth/domain/models/user_model.dart';

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository(Supabase.instance.client);
});

class ConnectionsRepository {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  ConnectionsRepository(this._supabase);

  // --- Directory / Discovery ---

  Future<List<UserModel>> searchDirectory({
    String? searchQuery,
    String? department,
    String? year,
    String? section,
  }) async {
    var query = _supabase.from('students').select();

    if (department != null && department.isNotEmpty) {
      query = query.eq('departmentId', department);
    }
    if (year != null && year.isNotEmpty) {
      query = query.eq('academicYear', year);
    }
    if (section != null && section.isNotEmpty) {
      query = query.eq('section', section);
    }

    try {
      final data = await query.limit(50);
      final users = data.map((row) {
        final map = Map<String, dynamic>.from(row);
        map['id'] =
            row['studentId'] ??
            row['id']; // Map UUID or studentId appropriately based on auth model
        return UserModel.fromJson(map);
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        return users
            .where(
              (u) =>
                  u.name.toLowerCase().contains(queryLower) ||
                  u.email.toLowerCase().contains(queryLower),
            )
            .toList();
      }

      return users;
    } catch (_) {
      return [];
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('studentId', id)
          .maybeSingle();

      if (response == null) return null;

      final map = Map<String, dynamic>.from(response);
      map['id'] = response['studentId'] ?? response['id'];
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Connections ---

  Stream<List<ConnectionModel>> streamConnections(String userId) {
    StreamSubscription? requesterSub;
    StreamSubscription? receiverSub;
    late StreamController<List<ConnectionModel>> controller;

    controller = StreamController<List<ConnectionModel>>(
      onListen: () {
        List<Map<String, dynamic>> requesterData = [];
        List<Map<String, dynamic>> receiverData = [];

        void update() {
          final combined = [...requesterData, ...receiverData];
          final uniqueMap = <String, Map<String, dynamic>>{};
          for (var row in combined) {
            uniqueMap[row['id']] = row;
          }
          if (!controller.isClosed) {
            controller.add(
              uniqueMap.values.map((row) => ConnectionModel.fromJson(row)).toList(),
            );
          }
        }

        requesterSub = _supabase
            .from('connections')
            .stream(primaryKey: ['id'])
            .eq('requesterId', userId)
            .listen((data) {
              requesterData = data;
              update();
            });

        receiverSub = _supabase
            .from('connections')
            .stream(primaryKey: ['id'])
            .eq('receiverId', userId)
            .listen((data) {
              receiverData = data;
              update();
            });
      },
      onCancel: () {
        requesterSub?.cancel();
        receiverSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> sendRequest(String requesterId, String receiverId) async {
    // Check if already exists
    try {
      final response = await _supabase
          .from('connections')
          .select()
          .eq('requesterId', requesterId)
          .eq('receiverId', receiverId)
          .maybeSingle();

      if (response == null) {
        final connection = ConnectionModel(
          id: _uuid.v4(),
          requesterId: requesterId,
          receiverId: receiverId,
          status: ConnectionStatus.pending,
          timestamp: DateTime.now(),
        );
        await _supabase.from('connections').insert(connection.toJson());
      }
    } catch (_) {}
  }

  Future<void> updateStatus(
    String connectionId,
    ConnectionStatus status,
  ) async {
    try {
      await _supabase
          .from('connections')
          .update({
            'status': status.name,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);
    } catch (_) {}
  }
}
