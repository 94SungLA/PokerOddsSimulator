import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/simulator/domain/models/card_model.dart';

enum SlotGroup { player, opponent, community }

class TableSlot {
  final SlotGroup group;
  final int playerIndex; // 0 for main player, 1+ for opponents
  final int cardIndex;   // 0 or 1 for hole cards, 0 to 4 for community cards

  const TableSlot({
    required this.group,
    required this.playerIndex,
    required this.cardIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableSlot &&
          runtimeType == other.runtimeType &&
          group == other.group &&
          playerIndex == other.playerIndex &&
          cardIndex == other.cardIndex;

  @override
  int get hashCode => Object.hash(group, playerIndex, cardIndex);

  @override
  String toString() => '${group.name}_${playerIndex}_$cardIndex';
}

class TableState {
  final CardModel? playerCard1;
  final CardModel? playerCard2;
  final List<CardModel?> communityCards;
  final List<List<CardModel?>> opponentHands;
  final List<String> opponentRanges; // matching length totalPlayers - 1, empty string means no range
  final int totalPlayers;
  final TableSlot? selectedSlot;

  TableState({
    this.playerCard1,
    this.playerCard2,
    required this.communityCards,
    required this.opponentHands,
    required this.opponentRanges,
    required this.totalPlayers,
    this.selectedSlot,
  });

  factory TableState.initial() {
    return TableState(
      playerCard1: null,
      playerCard2: null,
      communityCards: List.filled(5, null),
      opponentHands: List.generate(1, (_) => List.filled(2, null)),
      opponentRanges: List.filled(1, ''),
      totalPlayers: 2,
      selectedSlot: const TableSlot(group: SlotGroup.player, playerIndex: 0, cardIndex: 0),
    );
  }

  TableState copyWith({
    CardModel? Function()? playerCard1,
    CardModel? Function()? playerCard2,
    List<CardModel?>? communityCards,
    List<List<CardModel?>>? opponentHands,
    List<String>? opponentRanges,
    int? totalPlayers,
    TableSlot? Function()? selectedSlot,
  }) {
    return TableState(
      playerCard1: playerCard1 != null ? playerCard1() : this.playerCard1,
      playerCard2: playerCard2 != null ? playerCard2() : this.playerCard2,
      communityCards: communityCards ?? this.communityCards,
      opponentHands: opponentHands ?? this.opponentHands,
      opponentRanges: opponentRanges ?? this.opponentRanges,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
    );
  }

  bool isCardUsed(CardModel card) {
    if (playerCard1 == card || playerCard2 == card) return true;
    for (var c in communityCards) {
      if (c == card) return true;
    }
    for (var hand in opponentHands) {
      for (var c in hand) {
        if (c == card) return true;
      }
    }
    return false;
  }
}

class TableNotifier extends StateNotifier<TableState> {
  TableNotifier() : super(TableState.initial());

  void selectSlot(TableSlot slot) {
    state = state.copyWith(selectedSlot: () => slot);
  }

  void setTotalPlayers(int count) {
    if (count < 2 || count > 9) return;
    
    final diff = count - 1 - state.opponentHands.length;
    final newHands = List<List<CardModel?>>.from(state.opponentHands);
    final newRanges = List<String>.from(state.opponentRanges);
    
    if (diff > 0) {
      for (var i = 0; i < diff; i++) {
        newHands.add(List.filled(2, null));
        newRanges.add('');
      }
    } else if (diff < 0) {
      newHands.removeRange(newHands.length + diff, newHands.length);
      newRanges.removeRange(newRanges.length + diff, newRanges.length);
    }

    TableSlot? activeSlot = state.selectedSlot;
    if (activeSlot != null && activeSlot.group == SlotGroup.opponent && activeSlot.playerIndex > count - 1) {
      activeSlot = const TableSlot(group: SlotGroup.player, playerIndex: 0, cardIndex: 0);
    }

    state = state.copyWith(
      totalPlayers: count,
      opponentHands: newHands,
      opponentRanges: newRanges,
      selectedSlot: () => activeSlot,
    );
  }

  void setCardForActiveSlot(CardModel? card) {
    final activeSlot = state.selectedSlot;
    if (activeSlot == null) return;

    if (card != null && state.isCardUsed(card)) {
      _removeCardFromWhereverItIs(card);
    }

    _setCardInSlot(activeSlot, card);

    // Auto-advance slot selection for a fluid input experience
    _autoAdvanceSlot(activeSlot);
  }

  void removeCard(TableSlot slot) {
    _setCardInSlot(slot, null);
  }

  void setOpponentRange(int opponentIndex, String range) {
    final oppIndex = opponentIndex - 1;
    final newRanges = List<String>.from(state.opponentRanges);
    newRanges[oppIndex] = range;

    // Setting a range clears any specific card selections for this opponent
    final newOpp = List<List<CardModel?>>.from(state.opponentHands);
    newOpp[oppIndex] = List.filled(2, null);

    state = state.copyWith(
      opponentRanges: newRanges,
      opponentHands: newOpp,
    );
  }

  void clearTable() {
    state = TableState(
      playerCard1: null,
      playerCard2: null,
      communityCards: List.filled(5, null),
      opponentHands: List.generate(state.totalPlayers - 1, (_) => List.filled(2, null)),
      opponentRanges: List.filled(state.totalPlayers - 1, ''),
      totalPlayers: state.totalPlayers,
      selectedSlot: const TableSlot(group: SlotGroup.player, playerIndex: 0, cardIndex: 0),
    );
  }

  void loadState({
    required CardModel? playerCard1,
    required CardModel? playerCard2,
    required List<CardModel?> communityCards,
    required List<List<CardModel?>> opponentHands,
    required List<String> opponentRanges,
    required int totalPlayers,
  }) {
    state = TableState(
      playerCard1: playerCard1,
      playerCard2: playerCard2,
      communityCards: communityCards,
      opponentHands: opponentHands,
      opponentRanges: opponentRanges,
      totalPlayers: totalPlayers,
      selectedSlot: const TableSlot(group: SlotGroup.player, playerIndex: 0, cardIndex: 0),
    );
  }


  void _removeCardFromWhereverItIs(CardModel card) {
    if (state.playerCard1 == card) {
      state = state.copyWith(playerCard1: () => null);
    } else if (state.playerCard2 == card) {
      state = state.copyWith(playerCard2: () => null);
    } else {
      final idx = state.communityCards.indexOf(card);
      if (idx != -1) {
        final newComm = List<CardModel?>.from(state.communityCards);
        newComm[idx] = null;
        state = state.copyWith(communityCards: newComm);
      } else {
        for (var i = 0; i < state.opponentHands.length; i++) {
          final oppIdx = state.opponentHands[i].indexOf(card);
          if (oppIdx != -1) {
            final newOpp = List<List<CardModel?>>.from(state.opponentHands);
            newOpp[i] = List<CardModel?>.from(newOpp[i]);
            newOpp[i][oppIdx] = null;
            state = state.copyWith(opponentHands: newOpp);
            break;
          }
        }
      }
    }
  }

  void _setCardInSlot(TableSlot slot, CardModel? card) {
    if (slot.group == SlotGroup.player) {
      if (slot.cardIndex == 0) {
        state = state.copyWith(playerCard1: () => card);
      } else {
        state = state.copyWith(playerCard2: () => card);
      }
    } else if (slot.group == SlotGroup.community) {
      final newComm = List<CardModel?>.from(state.communityCards);
      newComm[slot.cardIndex] = card;
      state = state.copyWith(communityCards: newComm);
    } else if (slot.group == SlotGroup.opponent) {
      final newOpp = List<List<CardModel?>>.from(state.opponentHands);
      final oppIndex = slot.playerIndex - 1;
      newOpp[oppIndex] = List<CardModel?>.from(newOpp[oppIndex]);
      newOpp[oppIndex][slot.cardIndex] = card;

      // Assigning specific cards clears any range for this opponent
      final newRanges = List<String>.from(state.opponentRanges);
      if (card != null) {
        newRanges[oppIndex] = '';
      }

      state = state.copyWith(
        opponentHands: newOpp,
        opponentRanges: newRanges,
      );
    }
  }

  void _autoAdvanceSlot(TableSlot current) {
    TableSlot? nextSlot;
    if (current.group == SlotGroup.player) {
      if (current.cardIndex == 0) {
        nextSlot = const TableSlot(group: SlotGroup.player, playerIndex: 0, cardIndex: 1);
      } else {
        nextSlot = const TableSlot(group: SlotGroup.community, playerIndex: 0, cardIndex: 0);
      }
    } else if (current.group == SlotGroup.community) {
      if (current.cardIndex < 4) {
        nextSlot = TableSlot(group: SlotGroup.community, playerIndex: 0, cardIndex: current.cardIndex + 1);
      } else {
        if (state.opponentHands.isNotEmpty) {
          nextSlot = const TableSlot(group: SlotGroup.opponent, playerIndex: 1, cardIndex: 0);
        }
      }
    } else if (current.group == SlotGroup.opponent) {
      if (current.cardIndex == 0) {
        nextSlot = TableSlot(group: SlotGroup.opponent, playerIndex: current.playerIndex, cardIndex: 1);
      } else {
        final nextOppIndex = current.playerIndex + 1;
        if (nextOppIndex <= state.opponentHands.length) {
          nextSlot = TableSlot(group: SlotGroup.opponent, playerIndex: nextOppIndex, cardIndex: 0);
        } else {
          nextSlot = null;
        }
      }
    }
    state = state.copyWith(selectedSlot: () => nextSlot);
  }
}

final tableStateProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  return TableNotifier();
});
