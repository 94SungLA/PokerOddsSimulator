import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';
import 'package:frontend/features/simulator/ui/widgets/poker_card_widget.dart';
import 'package:frontend/features/simulator/ui/widgets/range_picker_dialog.dart';

class PokerTableWidget extends ConsumerWidget {
  const PokerTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.setTheme(context);
    final state = ref.watch(tableStateProvider);
    final notifier = ref.read(tableStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Opponent Hands Row/Grid
          _buildOpponents(context, state, notifier),
          const SizedBox(height: 20),

          // 2. Community Board Panel
          _buildCommunityBoard(state, notifier),
          const SizedBox(height: 20),

          // 3. Hero Player Cards
          _buildHeroHand(state, notifier),
        ],
      ),
    );
  }

  Widget _buildOpponents(BuildContext context, TableState state, TableNotifier notifier) {
    final count = state.opponentHands.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '對手手牌 (OPPONENTS - $count)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          children: List.generate(count, (index) {
            final opponentIndex = index + 1;
            final hand = state.opponentHands[index];
            final rangeStr = state.opponentRanges[index];
            final hasRange = rangeStr.isNotEmpty;

            return Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'P$opponentIndex',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (hasRange)
                    GestureDetector(
                      onTap: () {
                        RangePickerDialog.show(context, opponentIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rangeStr,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(2, (cardIdx) {
                      final slot = TableSlot(
                        group: SlotGroup.opponent,
                        playerIndex: opponentIndex,
                        cardIndex: cardIdx,
                      );
                      final card = hand[cardIdx];
                      final isActive = state.selectedSlot == slot;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: PokerCardWidget(
                          card: card,
                          isActive: isActive,
                          onTap: () {
                            notifier.selectSlot(slot);
                            RangePickerDialog.show(context, opponentIndex);
                          },
                          onClear: () => notifier.removeCard(slot),
                          width: 38,
                          height: 52,
                        ),
                      );
                    }),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommunityBoard(TableState state, TableNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '公共牌 (COMMUNITY CARDS)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final slot = TableSlot(
                group: SlotGroup.community,
                playerIndex: 0,
                cardIndex: index,
              );
              final card = state.communityCards[index];
              final isActive = state.selectedSlot == slot;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: PokerCardWidget(
                  card: card,
                  isActive: isActive,
                  onTap: () => notifier.selectSlot(slot),
                  onClear: () => notifier.removeCard(slot),
                  width: 52,
                  height: 72,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHand(TableState state, TableNotifier notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '你的手牌 (HERO HAND)',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final slot = TableSlot(
              group: SlotGroup.player,
              playerIndex: 0,
              cardIndex: index,
            );
            final card = index == 0 ? state.playerCard1 : state.playerCard2;
            final isActive = state.selectedSlot == slot;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: PokerCardWidget(
                card: card,
                isActive: isActive,
                onTap: () => notifier.selectSlot(slot),
                onClear: () => notifier.removeCard(slot),
                width: 64,
                height: 88,
              ),
            );
          }),
        ),
      ],
    );
  }
}
