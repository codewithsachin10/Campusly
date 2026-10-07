import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../data/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final userChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(chatRepositoryProvider);
  return repository.streamUserChats(user.id);
});

final chatMessagesStreamProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, chatId) {
      final repository = ref.watch(chatRepositoryProvider);
      ref.onDispose(() {
        repository.cancelMessagesSubscription(chatId);
      });
      return repository.streamMessages(chatId);
    });
