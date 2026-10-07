import 'dart:async';
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
  final repo = ChatRepository(Supabase.instance.client, dbService, syncService);
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

class ChatRepository {
  final SupabaseClient _supabase;
  final DatabaseService _dbService;
  final SyncEngineService _syncService;

  StreamSubscription? _chatsSubscription;
  final Map<String, StreamSubscription> _messagesSubscriptions = {};

  ChatRepository(this._supabase, this._dbService, this._syncService);

  void _ensureChatsSubscription(String userId) {
    if (_chatsSubscription != null) return;
    _chatsSubscription = _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .listen((data) async {
          final db = await _dbService.database;
          final batch = db.batch();
          for (var row in data) {
            final participants = List<String>.from(row['participants'] ?? []);
            batch.insert('chats', {
              'id': row['id'],
              'data': jsonEncode(row),
              'participants': participants.join(','),
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
          _dbService.notifyTableUpdated('chats');
        });
  }

  void _ensureMessagesSubscription(String chatId) {
    if (_messagesSubscriptions.containsKey(chatId)) return;
    _messagesSubscriptions[chatId] = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', chatId)
        .listen((data) async {
          final db = await _dbService.database;
          final batch = db.batch();
          for (var row in data) {
            final timestamp =
                DateTime.tryParse(
                  row['timestamp'] ?? '',
                )?.millisecondsSinceEpoch ??
                0;

            batch.insert('messages', {
              'id': row['id'],
              'chatId': chatId,
              'data': jsonEncode(row),
              'status': row['status'] ?? 'sent',
              'timestamp': timestamp,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit(noResult: true);
          _dbService.notifyTableUpdated('messages_$chatId');
        });
  }

  void cancelMessagesSubscription(String chatId) {
    _messagesSubscriptions[chatId]?.cancel();
    _messagesSubscriptions.remove(chatId);
  }

  void dispose() {
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
    for (final sub in _messagesSubscriptions.values) {
      sub.cancel();
    }
    _messagesSubscriptions.clear();
  }

  // --- Offline First Reads ---

  Stream<List<ChatModel>> streamUserChats(String userId) async* {
    _ensureChatsSubscription(userId);
    yield await _getLocalChats(userId);

    await for (final update in _dbService.onTableUpdated) {
      if (update == 'chats') {
        yield await _getLocalChats(userId);
      }
    }
  }

  Future<List<ChatModel>> _getLocalChats(String userId) async {
    final db = await _dbService.database;
    // Indexed WHERE query on participants column instead of loading all rows
    final results = await db.query(
      'chats',
      where: 'participants LIKE ?',
      whereArgs: ['%$userId%'],
      orderBy: 'lastUpdated DESC',
    );

    return results.map((row) {
      final data = jsonDecode(row['data'] as String);
      return ChatModel.fromJson(data);
    }).toList();
  }

  Stream<List<MessageModel>> streamMessages(String chatId) async* {
    _ensureMessagesSubscription(chatId);
    yield await _getLocalMessages(chatId);

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
