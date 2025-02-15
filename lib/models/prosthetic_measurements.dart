class ProstheticMeasurements {
  double lengthAboveKnee;
  double lengthBelowKnee;
  double circumferenceTop;
  double circumferenceBottom;
  double kneeFlexion;
  Color mainColor;
  String material;

  ProstheticMeasurements({
    this.lengthAboveKnee = 50,
    this.lengthBelowKnee = 40,
    this.circumferenceTop = 30,
    this.circumferenceBottom = 25,
    this.kneeFlexion = 0,
    this.mainColor = const Color(0xFF9E9E9E),
    this.material = 'Titanium',
  });

  Map<String, dynamic> toJson() => {
        'lengthAboveKnee': lengthAboveKnee,
        'lengthBelowKnee': lengthBelowKnee,
        'circumferenceTop': circumferenceTop,
        'circumferenceBottom': circumferenceBottom,
        'kneeFlexion': kneeFlexion,
        'mainColor': mainColor.value,
        'material': material,
      };

  factory ProstheticMeasurements.fromJson(Map<String, dynamic> json) {
    return ProstheticMeasurements(
      lengthAboveKnee: json['lengthAboveKnee']?.toDouble() ?? 50,
      lengthBelowKnee: json['lengthBelowKnee']?.toDouble() ?? 40,
      circumferenceTop: json['circumferenceTop']?.toDouble() ?? 30,
      circumferenceBottom: json['circumferenceBottom']?.toDouble() ?? 25,
      kneeFlexion: json['kneeFlexion']?.toDouble() ?? 0,
      mainColor: Color(json['mainColor'] ?? 0xFF9E9E9E),
      material: json['material'] ?? 'Titanium',
    );
  }
}
