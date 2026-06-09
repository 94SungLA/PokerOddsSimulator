class CardModel {
  final String rank; // '2'-'9', 'T', 'J', 'Q', 'K', 'A'
  final String suit; // 's' (Spades), 'h' (Hearts), 'd' (Diamonds), 'c' (Clubs)

  const CardModel({
    required this.rank,
    required this.suit,
  });

  /// Creates a CardModel from a 2-character string (e.g. "As")
  factory CardModel.fromString(String cardStr) {
    if (cardStr.length != 2) {
      throw ArgumentError('Invalid card string: $cardStr');
    }
    return CardModel(
      rank: cardStr[0],
      suit: cardStr[1],
    );
  }

  /// Converts the card to the API string format (e.g., "As")
  String toApiString() => '$rank$suit';

  String get suitName {
    switch (suit) {
      case 's': return 'Spades';
      case 'h': return 'Hearts';
      case 'd': return 'Diamonds';
      case 'c': return 'Clubs';
      default: return 'Unknown';
    }
  }

  String get suitSymbol {
    switch (suit) {
      case 's': return '♠';
      case 'h': return '♥';
      case 'd': return '♦';
      case 'c': return '♣';
      default: return '';
    }
  }

  bool get isRed {
    return suit == 'h' || suit == 'd';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          suit == other.suit;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;

  @override
  String toString() => toApiString();
}
