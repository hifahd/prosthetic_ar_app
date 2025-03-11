import 'dart:convert';
import 'package:flutter/material.dart';

class ProstheticConfig {
  final String id;
  final double length;
  final double width;
  final double circumferenceTop;
  final double circumferenceBottom;
  final double kneeFlexion;
  final Color color;
  final String material;
  final String modelPath;

  ProstheticConfig({
    required this.id,
    required this.length,
    required this.width,
    required this.circumferenceTop,
    required this.circumferenceBottom,
    required this.kneeFlexion,
    required this.color,
    required this.material,
    required this.modelPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'length': length,
      'width': width,
      'circumferenceTop': circumferenceTop,
      'circumferenceBottom': circumferenceBottom,
      'kneeFlexion': kneeFlexion,
      'color': color.value,
      'material': material,
      'modelPath': modelPath,
    };
  }

  factory ProstheticConfig.fromMap(Map<String, dynamic> map) {
    return ProstheticConfig(
      id: map['id'],
      length: map['length'],
      width: map['width'],
      circumferenceTop: map['circumferenceTop'],
      circumferenceBottom: map['circumferenceBottom'],
      kneeFlexion: map['kneeFlexion'],
      color: Color(map['color']),
      material: map['material'],
      modelPath: map['modelPath'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ProstheticConfig.fromJson(String source) =>
      ProstheticConfig.fromMap(json.decode(source));

  static String encode(List<ProstheticConfig> configs) =>
      json.encode(configs.map((config) => config.toMap()).toList());

  static List<ProstheticConfig> decode(String configs) =>
      (json.decode(configs) as List<dynamic>)
          .map<ProstheticConfig>((item) => ProstheticConfig.fromMap(item))
          .toList();

  // Copy with method to help with updates
  ProstheticConfig copyWith({
    String? id,
    double? length,
    double? width,
    double? circumferenceTop,
    double? circumferenceBottom,
    double? kneeFlexion,
    Color? color,
    String? material,
    String? modelPath,
  }) {
    return ProstheticConfig(
      id: id ?? this.id,
      length: length ?? this.length,
      width: width ?? this.width,
      circumferenceTop: circumferenceTop ?? this.circumferenceTop,
      circumferenceBottom: circumferenceBottom ?? this.circumferenceBottom,
      kneeFlexion: kneeFlexion ?? this.kneeFlexion,
      color: color ?? this.color,
      material: material ?? this.material,
      modelPath: modelPath ?? this.modelPath,
    );
  }
}
