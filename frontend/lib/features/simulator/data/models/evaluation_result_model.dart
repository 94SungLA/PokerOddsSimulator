class PotentialImprovement {
  final String improvement;
  final int outs;
  final List<String> outsCards;
  final double probability;

  PotentialImprovement({
    required this.improvement,
    required this.outs,
    required this.outsCards,
    required this.probability,
  });

  factory PotentialImprovement.fromJson(Map<String, dynamic> json) {
    return PotentialImprovement(
      improvement: json['improvement'] as String,
      outs: json['outs'] as int,
      outsCards: (json['outs_cards'] as List).map((e) => e as String).toList(),
      probability: (json['probability'] as num).toDouble(),
    );
  }
}

class EvaluationResult {
  final String handType;
  final int rankClass;
  final List<PotentialImprovement> potentialImprovements;
  final String handStrengthSummary;

  EvaluationResult({
    required this.handType,
    required this.rankClass,
    required this.potentialImprovements,
    required this.handStrengthSummary,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    var impList = json['potential_improvements'] as List;
    List<PotentialImprovement> parsedImps =
        impList.map((e) => PotentialImprovement.fromJson(e as Map<String, dynamic>)).toList();

    return EvaluationResult(
      handType: json['hand_type'] as String,
      rankClass: json['rank_class'] as int,
      potentialImprovements: parsedImps,
      handStrengthSummary: json['hand_strength_summary'] as String,
    );
  }
}
