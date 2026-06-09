class RangePreset {
  final String name;
  final String rangeStr;
  final String description;

  RangePreset({
    required this.name,
    required this.rangeStr,
    required this.description,
  });

  factory RangePreset.fromJson(Map<String, dynamic> json) {
    return RangePreset(
      name: json['name'] as String,
      rangeStr: json['range_str'] as String,
      description: json['description'] as String,
    );
  }
}
