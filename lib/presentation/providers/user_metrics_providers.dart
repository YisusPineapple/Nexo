import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/item_interaction.dart';
import '../../domain/usecases/user_metrics_usecases.dart';
import 'repository_providers.dart';

typedef InteractionParams = ({String id, ItemType type});

final itemInteractionProvider = FutureProvider.family<InteractionType?, InteractionParams>((ref, params) async {
  final repo = ref.watch(userMetricsRepositoryProvider);
  final result = await repo.getInteraction(itemId: params.id, itemType: params.type);
  return result.when(ok: (val) => val, err: (_) => null);
});

final userMetricsControllerProvider = Provider<UserMetricsController>((ref) {
  return UserMetricsController(ref);
});

class UserMetricsController {
  UserMetricsController(this._ref);
  final Ref _ref;

  Future<void> toggleInteraction(String itemId, ItemType itemType, InteractionType interaction) async {
    final useCase = ToggleInteractionUseCase(_ref.read(userMetricsRepositoryProvider));
    await useCase.call((itemId: itemId, itemType: itemType, interaction: interaction));
    _ref.invalidate(itemInteractionProvider((id: itemId, type: itemType)));
  }
}