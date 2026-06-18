import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/domain/models/card_model.dart';
import 'package:frontend/features/simulator/domain/providers/table_state.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/simulator/data/models/range_preset_model.dart';


class RangePickerDialog extends ConsumerStatefulWidget {
  final int opponentIndex;

  const RangePickerDialog({
    super.key,
    required this.opponentIndex,
  });

  static void show(BuildContext context, int opponentIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RangePickerDialog(opponentIndex: opponentIndex),
    );
  }

  @override
  ConsumerState<RangePickerDialog> createState() => _RangePickerDialogState();
}

class _RangePickerDialogState extends ConsumerState<RangePickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _rangeController;
  double _sliderValue = 0.0;
  
  List<RangePreset> _allPresets = [];
  List<RangePreset> _filteredPresets = [];
  bool _isLoadingPresets = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Retrieve initial range
    final state = ref.read(tableStateProvider);
    final initialRange = state.opponentRanges[widget.opponentIndex - 1];
    _rangeController = TextEditingController(text: initialRange);
    _sliderValue = _parsePercentage(initialRange);

    // If opponent already has a range, default to range tab (index 1)
    if (initialRange.isNotEmpty) {
      _tabController.index = 1;
    }

    _loadPresets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    try {
      final presets = await apiClient.getRanges();
      setState(() {
        _allPresets = presets;
        _filteredPresets = presets;
        _isLoadingPresets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPresets = false;
      });
    }
  }

  void _filterPresets(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPresets = _allPresets;
      } else {
        _filteredPresets = _allPresets
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.rangeStr.toLowerCase().contains(query.toLowerCase()) ||
                p.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  double _parsePercentage(String range) {
    if (range.startsWith('top_') && range.endsWith('%')) {
      final val = range.substring(4, range.length - 1);
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }

  void _onPresetSelected(String preset) {
    setState(() {
      _rangeController.text = preset;
      _sliderValue = _parsePercentage(preset);
    });
  }

  void _showCustomRangeInputDialog(BuildContext context) {
    final controller = TextEditingController(text: _rangeController.text);
    showDialog(
      context: context,
      builder: (ctx) {
        AppColors.setTheme(ctx);
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          '自訂手牌範圍 (Custom Range)',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '請輸入標準手牌標記，例如: QQ+, AK, AQs+, 22+',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: '例如: JJ+, AQs+, AKo',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              setState(() {
                _rangeController.text = text;
                _sliderValue = _parsePercentage(text);
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('確認', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    AppColors.setTheme(context);
    final state = ref.watch(tableStateProvider);
    final notifier = ref.read(tableStateProvider.notifier);
    final hand = state.opponentHands[widget.opponentIndex - 1];
    final selectedSlot = state.selectedSlot;
    
    final isOpponentActiveSlot = selectedSlot != null &&
        selectedSlot.group == SlotGroup.opponent &&
        selectedSlot.playerIndex == widget.opponentIndex;
    
    final activeCardIndex = isOpponentActiveSlot ? selectedSlot.cardIndex : 0;

    final usedCards = <CardModel>{};
    if (state.playerCard1 != null) usedCards.add(state.playerCard1!);
    if (state.playerCard2 != null) usedCards.add(state.playerCard2!);
    for (var card in state.communityCards) {
      if (card != null) usedCards.add(card);
    }
    for (var i = 0; i < state.opponentHands.length; i++) {
      for (var card in state.opponentHands[i]) {
        if (card != null) usedCards.add(card);
      }
    }
    final currentCard = hand[activeCardIndex];
    if (currentCard != null) {
      usedCards.remove(currentCard);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '對手 P${widget.opponentIndex} 設定',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: '具體手牌 (Cards)'),
                  Tab(text: '範圍設定 (Range)'),
                ],
              ),
              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSpecificCardsTab(
                      state,
                      notifier,
                      hand,
                      activeCardIndex,
                      usedCards,
                    ),

                    _buildRangeSettingsTab(notifier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificCardsTab(
    TableState state,
    TableNotifier notifier,
    List<CardModel?> hand,
    int activeCardIndex,
    Set<CardModel> usedCards,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (cardIdx) {
            final isEditingThisCard = activeCardIndex == cardIdx;
            final card = hand[cardIdx];
            final slot = TableSlot(
              group: SlotGroup.opponent,
              playerIndex: widget.opponentIndex,
              cardIndex: cardIdx,
            );

            return GestureDetector(
              onTap: () {
                notifier.selectSlot(slot);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                width: 54,
                height: 72,
                decoration: BoxDecoration(
                  color: card == null ? AppColors.cardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEditingThisCard
                        ? AppColors.primary
                        : AppColors.border,
                    width: isEditingThisCard ? 2.0 : 1.0,
                  ),
                  boxShadow: isEditingThisCard
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (card != null) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.rank,
                            style: TextStyle(
                              color: card.isRed ? AppColors.suitRed : AppColors.suitBlack,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            card.suitSymbol,
                            style: TextStyle(
                              color: card.isRed ? AppColors.suitRed : AppColors.suitBlack,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            notifier.removeCard(slot);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
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
                    ] else ...[
                      Icon(
                        Icons.add,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
        Divider(color: AppColors.border, height: 16),
        Expanded(
          child: _buildMiniCardPicker(usedCards, (card) {
            final slot = TableSlot(
              group: SlotGroup.opponent,
              playerIndex: widget.opponentIndex,
              cardIndex: activeCardIndex,
            );
            notifier.selectSlot(slot);
            notifier.setCardForActiveSlot(card);
          }),
        ),
      ],
    );
  }

  Widget _buildMiniCardPicker(Set<CardModel> usedCards, ValueChanged<CardModel> onCardSelected) {
    final suits = ['s', 'h', 'd', 'c'];
    final ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: suits.length,
      itemBuilder: (context, index) {
        final suit = suits[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _buildSuitLabel(suit),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ranks.map((rank) {
                      final card = CardModel(rank: rank, suit: suit);
                      final isUsed = usedCards.contains(card);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
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
      },
    );
  }

  Widget _buildSuitLabel(String suit) {
    String symbol = '';
    Color color = Colors.white;
    Color bgColor = Colors.transparent;

    switch (suit) {
      case 's':
        symbol = '♠';
        color = AppColors.suitBlack;
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1); // Same bg as clubs
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
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        break;
    }

    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSettingsTab(TableNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '強手牌比例 (Percentile):',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_sliderValue.round()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.black),
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_sliderValue.round()}%',
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                  if (value > 0) {
                    _rangeController.text = 'top_${value.round()}%';
                  } else {
                    _rangeController.text = '';
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 4),

          Text(
            '快捷範圍選擇與搜尋 (Presets Search):',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SearchBar(
            onChanged: _filterPresets,
            hintText: '搜尋預設範圍... (如 QQ+, Pocket, 10%)',
            hintStyle: WidgetStatePropertyAll(
              TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
            ),
            textStyle: WidgetStatePropertyAll(
              TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            leading: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
            backgroundColor: WidgetStatePropertyAll(AppColors.cardBackground),
            elevation: const WidgetStatePropertyAll(0),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoadingPresets
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredPresets.isEmpty
                    ? Center(child: Text('無符合的範圍預設', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)))
                    : ListView.builder(
                        itemCount: _filteredPresets.length,
                        itemBuilder: (context, idx) {
                          final preset = _filteredPresets[idx];
                          final isSelected = _rangeController.text == preset.rangeStr;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(preset.name, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(preset.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              trailing: Text(preset.rangeStr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                              onTap: () {
                                _onPresetSelected(preset.rangeStr);
                              },
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showCustomRangeInputDialog(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('自訂輸入 Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    notifier.setOpponentRange(widget.opponentIndex, _rangeController.text.trim());
                    Navigator.of(context).pop();
                  },
                  child: const Text('套用範圍', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
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
    AppColors.setTheme(context);
    final color = card.isRed ? AppColors.suitRed : AppColors.suitBlack;
    final symbol = card.suitSymbol;

    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: Opacity(
        opacity: isUsed ? 0.15 : 1.0,
        child: Container(
          width: 28,
          height: 38,
          decoration: BoxDecoration(
            color: isUsed ? AppColors.disabledCard : (Theme.of(context).brightness == Brightness.dark ? AppColors.cardBackground : Colors.white),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isUsed ? AppColors.border : (Theme.of(context).brightness == Brightness.dark ? AppColors.border : Colors.grey.shade200),
              width: 1.0,
            ),
            boxShadow: isUsed || Theme.of(context).brightness == Brightness.dark
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
              Positioned(
                top: 1,
                left: 1.5,
                child: Text(
                  card.rank,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1.5,
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
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
