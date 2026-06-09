import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/simulator/data/models/history_record_model.dart';

class HistoryNotifier extends AsyncNotifier<List<HistoryRecord>> {
  @override
  FutureOr<List<HistoryRecord>> build() async {
    return _fetchHistory();
  }

  Future<List<HistoryRecord>> _fetchHistory() async {
    return await apiClient.getHistory();
  }

  Future<void> refreshHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHistory());
  }

  Future<void> saveRecord({
    required List<String> heroHand,
    required List<dynamic> opponentRanges,
    required List<String> communityCards,
    required double winRate,
    required double tieRate,
    required double loseRate,
  }) async {
    await apiClient.saveHistory(
      heroHand: heroHand,
      opponentRanges: opponentRanges,
      communityCards: communityCards,
      winRate: winRate,
      tieRate: tieRate,
      loseRate: loseRate,
    );
    // Invalidate the cache to reload
    ref.invalidateSelf();
  }

  Future<void> deleteRecord(int id) async {
    await apiClient.deleteHistory(id);
    ref.invalidateSelf();
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<HistoryRecord>>(() {
  return HistoryNotifier();
});
