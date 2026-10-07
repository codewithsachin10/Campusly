import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/connection_model.dart';
import '../../data/connections_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final connectionsStreamProvider =
    StreamProvider.autoDispose<List<ConnectionModel>>((ref) {
      final user = ref.watch(authControllerProvider).value;
      if (user == null) return const Stream.empty();

      final repository = ref.watch(connectionsRepositoryProvider);
      return repository.streamConnections(user.id);
    });
