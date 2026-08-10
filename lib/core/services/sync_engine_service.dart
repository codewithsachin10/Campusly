import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

final syncEngineProvider = Provider<SyncEngineService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final service = SyncEngineService(dbService, connectivity);
  ref.onDispose(() => service.dispose());
  return service;
});

class SyncEngineService {
  final DatabaseService _dbService;
  final ConnectivityService _connectivityService;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  SyncEngineService(this._dbService, this._connectivityService) {
    // Listen for connection changes to trigger sync
    _connectivityService.connectionStatusStream.listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });
  }

  Future<void> enqueueAction(
    String action,
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final db = await _dbService.database;
    final actionId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('sync_queue', {
      'id': actionId,
      'action': action,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Try syncing immediately if online
    if (_connectivityService.isOnline) {
      syncNow();
    }
  }

  Future<void> syncNow() async {
    if (_isSyncing || !_connectivityService.isOnline) return;

    _isSyncing = true;
    try {
      final db = await _dbService.database;

      // Get all pending actions
      final pendingActions = await db.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'createdAt ASC',
      );

      for (var actionRow in pendingActions) {
        final actionId = actionRow['id'] as String;
        final action = actionRow['action'] as String;
        final payload =
            jsonDecode(actionRow['payload'] as String) as Map<String, dynamic>;

        bool success = false;

        try {
          success = await _processAction(action, payload);
        } catch (e) {
          debugPrint('Sync Error for action $actionId: $e');
        }

        if (success) {
          // Remove from queue upon success
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [actionId]);
        } else {
          // Increment retry count
          final currentRetries = (actionRow['retryCount'] as int?) ?? 0;
          await db.update(
            'sync_queue',
            {'retryCount': currentRetries + 1},
            where: 'id = ?',
            whereArgs: [actionId],
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    switch (action) {
      case 'create_message':
        final messageId = payload['id'] as String;

        // Remove local-only keys before uploading if any
        final dataToUpload = Map<String, dynamic>.from(payload);
        dataToUpload.remove('localStatus');

        await _supabase.from('messages').upsert(dataToUpload);

        // Also update local db status to sent
        final db = await _dbService.database;
        await db.update(
          'messages',
          {'status': 'sent'},
          where: 'id = ?',
          whereArgs: [messageId],
        );
        return true;

      case 'update_profile':
        final userId = payload['userId'] as String;
        final data = Map<String, dynamic>.from(payload);
        data.remove('userId');

        await _supabase.from('students').update(data).eq('studentId', userId);
        return true;

      default:
        debugPrint('Unknown sync action: $action');
        // Return true to remove unknown actions and prevent blocking the queue
        return true;
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
