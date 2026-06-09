import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/domain/models/card_model.dart';

class PokerCardWidget extends StatelessWidget {
  final CardModel? card;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final double width;
  final double height;

  const PokerCardWidget({
    super.key,
    required this.card,
    required this.isActive,
    required this.onTap,
    this.onClear,
    this.width = 60,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    final hasCard = card != null;
    final isSmall = width < 50;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card Surface Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: hasCard ? Colors.white : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.borderActive
                    : (hasCard ? Colors.white : AppColors.border),
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow: hasCard
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : (isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : []),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasCard
                  ? _buildLoadedCard(card!, isSmall)
                  : _buildEmptyCard(),
            ),
          ),
          // Clear Button
          if (hasCard && onClear != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadedCard(CardModel cardModel, bool isSmall) {
    final color = cardModel.isRed ? AppColors.suitRed : AppColors.suitBlack;
    final symbol = cardModel.suitSymbol;

    return Container(
      padding: EdgeInsets.all(isSmall ? 2 : 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: isSmall
          ? _buildSmallCardContent(cardModel, color, symbol)
          : _buildStandardCardContent(cardModel, color, symbol),
    )
        .animate()
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 120.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 100.ms);
  }

  // Simplified layout for tiny cards (e.g. opponents hands)
  Widget _buildSmallCardContent(CardModel cardModel, Color color, String symbol) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cardModel.rank,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 1),
          Text(
            symbol,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // Traditional corner indexes layout for standard cards
  Widget _buildStandardCardContent(CardModel cardModel, Color color, String symbol) {
    return Stack(
      children: [
        // Top Left Index
        Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cardModel.rank,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Text(
                symbol,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        // Center Icon
        Align(
          alignment: Alignment.center,
          child: Text(
            symbol,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: 26,
            ),
          ),
        ),
        // Bottom Right Index (flipped)
        Align(
          alignment: Alignment.bottomRight,
          child: RotatedBox(
            quarterTurns: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cardModel.rank,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                Text(
                  symbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard() {
    final activeColor = AppColors.borderActive;
    final inactiveColor = AppColors.border.withValues(alpha: 0.7);
    
    return Center(
      child: Icon(
        isActive ? Icons.add : Icons.add,
        color: isActive ? activeColor : inactiveColor,
        size: isActive ? 22 : 18,
      ),
    );
  }
}
