class SimulationResult {
  final int simulationsRun;
  final double elapsedTimeMs;
  final List<PlayerResult> playerResults;

  SimulationResult({
    required this.simulationsRun,
    required this.elapsedTimeMs,
    required this.playerResults,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    var list = json['player_results'] as List;
    List<PlayerResult> resultsList = list.map((i) => PlayerResult.fromJson(i)).toList();

    return SimulationResult(
      simulationsRun: json['simulations_run'] as int,
      elapsedTimeMs: (json['elapsed_time_ms'] as num).toDouble(),
      playerResults: resultsList,
    );
  }
}

class PlayerResult {
  final int playerIndex;
  final List<String> hand;
  final double winRate;
  final double tieRate;
  final double loseRate;
  final Map<String, double> handTypeDistribution;

  PlayerResult({
    required this.playerIndex,
    required this.hand,
    required this.winRate,
    required this.tieRate,
    required this.loseRate,
    required this.handTypeDistribution,
  });

  factory PlayerResult.fromJson(Map<String, dynamic> json) {
    var handList = (json['hand'] as List).map((item) => item as String).toList();
    
    // Map hand type distribution
    var distributionRaw = json['hand_type_distribution'] as Map<String, dynamic>;
    Map<String, double> distribution = {};
    distributionRaw.forEach((key, value) {
      distribution[key] = (value as num).toDouble();
    });

    return PlayerResult(
      playerIndex: json['player_index'] as int,
      hand: handList,
      winRate: (json['win_rate'] as num).toDouble(),
      tieRate: (json['tie_rate'] as num).toDouble(),
      loseRate: (json['lose_rate'] as num).toDouble(),
      handTypeDistribution: distribution,
    );
  }
}
