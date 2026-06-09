import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/simulator/data/models/evaluation_result_model.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';

class EvaluationNotifier extends AutoDisposeAsyncNotifier<EvaluationResult?> {
  @override
  FutureOr<EvaluationResult?> build() async {
    final tableState = ref.watch(tableStateProvider);
    
    if (tableState.playerCard1 == null || tableState.playerCard2 == null) {
      return null;
    }
    
    final commCards = tableState.communityCards
        .where((c) => c != null)
        .map((c) => c!.toApiString())
        .toList();
        
    if (commCards.length >= 3 && commCards.length <= 5) {
      final heroHand = [
        tableState.playerCard1!.toApiString(),
        tableState.playerCard2!.toApiString()
      ];
      final allCards = [...heroHand, ...commCards];
      
      return await apiClient.evaluate(cards: allCards);
    }
    
    return null;
  }
}

final evaluationProvider = AutoDisposeAsyncNotifierProvider<EvaluationNotifier, EvaluationResult?>(() {
  return EvaluationNotifier();
});
