import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/simulator/data/models/simulation_result_model.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';

class AiCoachNotifier extends StateNotifier<AsyncValue<String?>> {
  AiCoachNotifier() : super(const AsyncValue.data(null));

  Future<void> requestExplanation({
    required TableState tableState,
    required SimulationResult result,
  }) async {
    state = const AsyncValue.loading();
    try {
      final heroHand = [
        tableState.playerCard1!.toApiString(),
        tableState.playerCard2!.toApiString()
      ];

      final communityCards = tableState.communityCards
          .where((c) => c != null)
          .map((c) => c!.toApiString())
          .toList();

      final opponentRanges = <dynamic>[];
      for (var i = 0; i < tableState.opponentHands.length; i++) {
        final hand = tableState.opponentHands[i];
        final range = tableState.opponentRanges[i];
        if (range.isNotEmpty) {
          opponentRanges.add(range);
        } else if (hand[0] != null && hand[1] != null) {
          opponentRanges.add([hand[0]!.toApiString(), hand[1]!.toApiString()]);
        } else {
          opponentRanges.add('');
        }
      }

      final heroResult = result.playerResults.firstWhere((p) => p.playerIndex == 0);

      final explanation = await apiClient.explain(
        playerHand: heroHand,
        communityCards: communityCards,
        opponentRanges: opponentRanges,
        winRate: heroResult.winRate,
        tieRate: heroResult.tieRate,
        loseRate: heroResult.loseRate,
      );
      
      if (!mounted) return;
      state = AsyncValue.data(explanation);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final aiCoachProvider = StateNotifierProvider.autoDispose<AiCoachNotifier, AsyncValue<String?>>((ref) {
  return AiCoachNotifier();
});

