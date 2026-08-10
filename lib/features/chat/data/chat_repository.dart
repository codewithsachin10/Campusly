import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/sync_engine_service.dart';
import '../domain/models/chat_model.dart';
import '../domain/models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final syncService = ref.watch(syncEngineProvider);
  return ChatRepository(Supabase.instance.client, dbService, syncService);
});

class ChatRepository {
  final SupabaseClient _supabase;
  final DatabaseService _dbService;
  final SyncEngineService _syncService;

  ChatRepository(this._supabase, this._dbService, this._syncService);

  // --- Offline First Reads ---

  Stream<List<ChatModel>> streamUserChats(String userId) async* {
    // 1. Yield from local DB initially
    yield await _getLocalChats(userId);

    // 2. Start a Supabase listener that updates local DB
    _supabase.from('chats').stream(primaryKey: ['id']).listen((data) async {
      final db = await _dbService.database;
      for (var row in data) {
        final participants = List<String>.from(row['participants'] ?? []);
        if (!participants.contains(userId)) continue;

        await db.insert('chats', {
          'id': row['id'],
          'data': jsonEncode(row),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      _dbService.notifyTableUpdated('chats');
    });

    // 3. Yield whenever local DB updates
    await for (final _ in _dbService.onTableUpdated) {
      yield await _getLocalChats(userId);
    }
  }

  Future<List<ChatModel>> _getLocalChats(String userId) async {
    final db = await _dbService.database;
    final results = await db.query('chats');

    final chats = results.map((row) {
      final data = jsonDecode(row['data'] as String);
      return ChatModel.fromJson(data);
    }).toList();

    // Filter locally and sort
    final filtered = chats
        .where((c) => c.participants.contains(userId))
        .toList();
    filtered.sort(
      (a, b) => (b.lastMessageTime ?? DateTime.now()).compareTo(
        a.lastMessageTime ?? DateTime.now(),
      ),
    );
    return filtered;
  }

  Stream<List<MessageModel>> streamMessages(String chatId) async* {
    yield await _getLocalMessages(chatId);

    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', chatId)
        .listen((data) async {
          final db = await _dbService.database;
          for (var row in data) {
            final timestamp =
                DateTime.tryParse(
                  row['timestamp'] ?? '',
                )?.millisecondsSinceEpoch ??
                0;

            await db.insert('messages', {
              'id': row['id'],
              'chatId': chatId,
              'data': jsonEncode(row),
              'status': row['status'] ?? 'sent',
              'timestamp': timestamp,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          _dbService.notifyTableUpdated('messages_$chatId');
        });

    await for (final update in _dbService.onTableUpdated) {
      if (update == 'messages_$chatId') {
        yield await _getLocalMessages(chatId);
      }
    }
  }

  Future<List<MessageModel>> _getLocalMessages(String chatId) async {
    final db = await _dbService.database;
    final results = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );

    return results.map((row) {
      final data = jsonDecode(row['data'] as String);
      return MessageModel.fromJson(data).copyWith(
        // Use localStatus if we want to show pending ticks
        localStatus: row['status'] as String?,
      );
    }).toList();
  }

  // --- Offline First Writes ---

  Future<void> sendMessage(MessageModel message) async {
    final db = await _dbService.database;
    // For supabase, generate UUID locally or just use message.id which should be a UUID
    final msgId = message.id.isNotEmpty
        ? message.id
        : 'local_${DateTime.now().millisecondsSinceEpoch}';

    final msgData = message
        .copyWith(id: msgId, status: MessageStatus.sent)
        .toJson();
    msgData['localStatus'] = 'pending';

    // 1. Write to local DB as 'pending'
    await db.insert('messages', {
      'id': msgId,
      'chatId': message.chatId,
      'data': jsonEncode(msgData),
      'status': 'pending',
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Also update local chat snippet immediately
    final chatResults = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [message.chatId],
    );
    if (chatResults.isNotEmpty) {
      final chatData = jsonDecode(chatResults.first['data'] as String);
      chatData['lastMessage'] = message.type == MessageType.text
          ? message.text
          : '[${message.type.name}]';
      chatData['lastMessageTime'] = message.timestamp.toIso8601String();
      await db.update(
        'chats',
        {'data': jsonEncode(chatData)},
        where: 'id = ?',
        whereArgs: [message.chatId],
      );
      _dbService.notifyTableUpdated('chats');
    }

    _dbService.notifyTableUpdated('messages_${message.chatId}');

    // 2. Add to Sync Queue
    await _syncService.enqueueAction(
      'create_message',
      msgData,
      id: 'msg_$msgId',
    );
  }

  Future<String> createOrGetPrivateChat(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final response = await _supabase
          .from('chats')
          .select()
          .eq('type', ChatType.private.name)
          .contains('participants', [currentUserId, otherUserId]);

      if (response.isNotEmpty) {
        return response.first['id'] as String;
      }

      final newChat = ChatModel(
        id: '', // Supabase will generate UUID
        type: ChatType.private,
        participants: [currentUserId, otherUserId],
      );
      final insertResp = await _supabase
          .from('chats')
          .insert(newChat.toJson())
          .select();
      return insertResp.first['id'] as String;
    } catch (_) {
      return '';
    }
  }

  Future<String> createGroupChat(
    String currentUserId,
    String name,
    List<String> participants,
  ) async {
    final allParticipants = Set<String>.from(participants);
    allParticipants.add(currentUserId);

    final newChat = ChatModel(
      id: '',
      type: ChatType.group,
      participants: allParticipants.toList(),
      groupMetadata: {
        'name': name,
        'adminIds': [currentUserId],
      },
    );
    try {
      final insertResp = await _supabase
          .from('chats')
          .insert(newChat.toJson())
          .select();
      return insertResp.first['id'] as String;
    } catch (_) {
      return '';
    }
  }

  Future<void> markMessageRead(String chatId, String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'status': MessageStatus.read.name})
          .eq('chatId', chatId)
          .eq('id', messageId);
    } catch (_) {}
  }
}
