class HistoryRecord {
  final int id;
  final List<String> heroHand;
  final List<dynamic> opponentRanges;
  final List<String> communityCards;
  final double winRate;
  final double tieRate;
  final double loseRate;
  final DateTime timestamp;

  HistoryRecord({
    required this.id,
    required this.heroHand,
    required this.opponentRanges,
    required this.communityCards,
    required this.winRate,
    required this.tieRate,
    required this.loseRate,
    required this.timestamp,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id'] as int,
      heroHand: (json['hero_hand'] as List).map((e) => e as String).toList(),
      opponentRanges: json['opponent_ranges'] as List,
      communityCards: (json['community_cards'] as List).map((e) => e as String).toList(),
      winRate: (json['win_rate'] as num).toDouble(),
      tieRate: (json['tie_rate'] as num).toDouble(),
      loseRate: (json['lose_rate'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hero_hand': heroHand,
      'opponent_ranges': opponentRanges,
      'community_cards': communityCards,
      'win_rate': winRate,
      'tie_rate': tieRate,
      'lose_rate': loseRate,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}
