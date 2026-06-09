import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/domain/models/card_model.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';
import 'package:frontend/features/simulator/domain/providers/simulation_provider.dart';
import 'package:frontend/features/simulator/ui/widgets/card_picker_widget.dart';
import 'package:frontend/features/simulator/ui/widgets/poker_table_widget.dart';
import 'package:frontend/features/simulator/ui/widgets/results_panel_widget.dart';

class SimulatorPage extends ConsumerWidget {
  const SimulatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tableStateProvider);
    final notifier = ref.read(tableStateProvider.notifier);
    final simState = ref.watch(simulationProvider);

    // Automatically reset simulation results when table state cards or configurations change
    ref.listen<TableState>(tableStateProvider, (previous, next) {
      if (previous == null) return;
      
      final cardChanged = previous.playerCard1 != next.playerCard1 ||
          previous.playerCard2 != next.playerCard2 ||
          previous.totalPlayers != next.totalPlayers ||
          !_listEquals(previous.communityCards, next.communityCards) ||
          !_listEquals(previous.opponentHands, next.opponentHands) ||
          !_listEquals(previous.opponentRanges, next.opponentRanges);

      if (cardChanged) {
        ref.read(simulationProvider.notifier).reset();
      }
    });

    // Collect all cards currently placed on the table to disable them in the picker
    final usedCards = <CardModel>{};
    if (state.playerCard1 != null) usedCards.add(state.playerCard1!);
    if (state.playerCard2 != null) usedCards.add(state.playerCard2!);
    for (var card in state.communityCards) {
      if (card != null) usedCards.add(card);
    }
    for (var hand in state.opponentHands) {
      for (var card in hand) {
        if (card != null) usedCards.add(card);
      }
    }

    final isReadyToSimulate = state.playerCard1 != null && state.playerCard2 != null;
    final isLoading = simState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PokerLab',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              notifier.clearTable();
              ref.read(simulationProvider.notifier).reset();
            },
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
            label: const Text(
              '重設',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Controls (Players Count chips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    '玩家人數:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(8, (index) {
                          final count = index + 2;
                          final isSelected = state.totalPlayers == count;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: ChoiceChip(
                              label: Text('$count 人'),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 1.0,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 12.5,
                              ),
                              showCheckmark: false,
                              onSelected: isLoading
                                  ? null
                                  : (_) => notifier.setTotalPlayers(count),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable Poker Table felt
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const PokerTableWidget(),
                    const SizedBox(height: 18),
                    
                    // Run Simulation Gradient Button
                    if (!isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: isReadyToSimulate
                                ? const LinearGradient(
                                    colors: [AppColors.primary, AppColors.accent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: isReadyToSimulate ? null : AppColors.disabledCard,
                            boxShadow: isReadyToSimulate
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isReadyToSimulate
                                ? () => ref
                                    .read(simulationProvider.notifier)
                                    .runSimulation(state)
                                : null,
                            icon: const Icon(Icons.analytics_outlined, size: 18),
                            label: const Text(
                              '開始計算勝率 (Run Simulation)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Simulation States: loading / error / results
                    simState.when(
                      data: (result) {
                        if (result == null) return const SizedBox.shrink();
                        return ResultsPanelWidget(result: result);
                      },
                      loading: () => _buildLoadingWidget(),
                      error: (err, stack) => _buildErrorWidget(err.toString(), state, ref),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Card Picker Widget
            CardPickerWidget(
              usedCards: usedCards,
              onCardSelected: isLoading
                  ? (_) {}
                  : (card) {
                      notifier.setCardForActiveSlot(card);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '正在執行 10,000 次 Monte Carlo 模擬...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '系統正在隨機補齊剩餘卡牌並計算各玩家贏面',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, TableState state, WidgetRef ref) {
    final cleanMsg = error.replaceAll('Exception: ', '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.loseColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.loseColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cleanMsg,
                  style: const TextStyle(
                    color: AppColors.loseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ref.read(simulationProvider.notifier).runSimulation(state),
              icon: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
              label: const Text(
                '重試',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers to deeply compare lists for equality checks
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] is List && b[i] is List) {
        if (!_listEquals(a[i] as List, b[i] as List)) return false;
      } else if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
