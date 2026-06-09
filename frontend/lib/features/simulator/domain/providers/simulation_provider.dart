import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/simulator/data/models/simulation_result_model.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';
import 'package:frontend/features/simulator/domain/providers/settings_provider.dart';
import 'package:frontend/features/simulator/domain/providers/history_provider.dart';

class SimulationNotifier extends AsyncNotifier<SimulationResult?> {
  @override
  FutureOr<SimulationResult?> build() {
    return null; // Initial state is idle
  }

  Future<void> runSimulation(TableState tableState) async {
    if (tableState.playerCard1 == null || tableState.playerCard2 == null) {
      state = AsyncValue.error(
        Exception('Hero 手牌必須有兩張牌才能開始模擬'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // 1. Format Hero hand
      final playerHand = [
        tableState.playerCard1!.toApiString(),
        tableState.playerCard2!.toApiString()
      ];

      // 2. Format Opponents hands. Ensure each opponent hand is either 0 or 2 cards.
      final opponentHands = tableState.opponentHands.map((hand) {
        if (hand[0] != null && hand[1] != null) {
          return [hand[0]!.toApiString(), hand[1]!.toApiString()];
        }
        return <String>[];
      }).toList();

      // 3. Format Community cards
      final communityCards = tableState.communityCards
          .where((c) => c != null)
          .map((c) => c!.toApiString())
          .toList();

      // Read simulation count from settings
      final settings = ref.read(settingsProvider);

      // 4. Trigger simulation API
      final result = await apiClient.simulate(
        playerHand: playerHand,
        opponentHands: opponentHands,
        opponentRanges: tableState.opponentRanges,
        communityCards: communityCards,
        totalPlayers: tableState.totalPlayers,
        simulations: settings.simulationsCount,
      );

      // 5. Automatically persist simulation in History
      try {
        final heroResult = result.playerResults.firstWhere((p) => p.playerIndex == 0);
        
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

        await ref.read(historyProvider.notifier).saveRecord(
          heroHand: playerHand,
          opponentRanges: opponentRanges,
          communityCards: communityCards,
          winRate: heroResult.winRate,
          tieRate: heroResult.tieRate,
          loseRate: heroResult.loseRate,
        );
      } catch (e) {
        // Failure to save to history should not prevent results from displaying
        print('自動儲存歷史紀錄失敗: $e');
      }

      return result;
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final simulationProvider = AsyncNotifierProvider<SimulationNotifier, SimulationResult?>(() {
  return SimulationNotifier();
});

