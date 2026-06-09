import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/domain/models/card_model.dart';

class CardPickerWidget extends StatelessWidget {
  final Set<CardModel> usedCards;
  final ValueChanged<CardModel> onCardSelected;

  const CardPickerWidget({
    super.key,
    required this.usedCards,
    required this.onCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suits = ['s', 'h', 'd', 'c'];
    final ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '選擇卡牌 (CHOOSE CARD)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '點擊放入當前橘框欄位',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Suit rows
          ...suits.map((suit) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                children: [
                  _buildSuitLabel(suit),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ranks.map((rank) {
                          final card = CardModel(rank: rank, suit: suit);
                          final isUsed = usedCards.contains(card);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: _CardPickerTile(
                              card: card,
                              isUsed: isUsed,
                              onTap: () => onCardSelected(card),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuitLabel(String suit) {
    String symbol = '';
    Color color = Colors.white;
    Color bgColor = Colors.transparent;

    switch (suit) {
      case 's':
        symbol = '♠';
        color = Colors.white;
        bgColor = const Color(0xFF1E293B);
        break;
      case 'h':
        symbol = '♥';
        color = AppColors.suitRed;
        bgColor = AppColors.suitRed.withValues(alpha: 0.1);
        break;
      case 'd':
        symbol = '♦';
        color = AppColors.suitRed;
        bgColor = AppColors.suitRed.withValues(alpha: 0.1);
        break;
      case 'c':
        symbol = '♣';
        color = const Color(0xFF10B981); // Emerald Green
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        break;
    }

    return Container(
      width: 30,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CardPickerTile extends StatelessWidget {
  final CardModel card;
  final bool isUsed;
  final VoidCallback onTap;

  const _CardPickerTile({
    required this.card,
    required this.isUsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? AppColors.suitRed : AppColors.suitBlack;
    final symbol = card.suitSymbol;

    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: Opacity(
        opacity: isUsed ? 0.15 : 1.0,
        child: Container(
          width: 32,
          height: 44,
          decoration: BoxDecoration(
            color: isUsed ? AppColors.disabledCard : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isUsed ? AppColors.border : Colors.grey.shade200,
              width: 1.0,
            ),
            boxShadow: isUsed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    )
                  ],
          ),
          child: Stack(
            children: [
              // Rank Text
              Positioned(
                top: 2,
                left: 2.5,
                child: Text(
                  card.rank,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              // Suit Symbol
              Positioned(
                bottom: 2,
                right: 2.5,
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
