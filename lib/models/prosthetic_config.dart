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
    this.circumferenceTop = 30,
    this.circumferenceBottom = 25,
    this.kneeFlexion = 0,
    required this.color,
    this.material = 'Titanium',
    required this.modelPath,
  });

  Map<String, dynamic> toJson() => {
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

  factory ProstheticConfig.fromJson(Map<String, dynamic> json) =>
      ProstheticConfig(
        id: json['id'],
        length: json['length'],
        width: json['width'],
        circumferenceTop: json['circumferenceTop'] ?? 30,
        circumferenceBottom: json['circumferenceBottom'] ?? 25,
        kneeFlexion: json['kneeFlexion'] ?? 0,
        color: Color(json['color']),
        material: json['material'] ?? 'Titanium',
        modelPath: json['modelPath'],
      );

  static String encode(List<ProstheticConfig> configs) => json.encode(
        configs.map((config) => config.toJson()).toList(),
      );

  static List<ProstheticConfig> decode(String configs) =>
      (json.decode(configs) as List<dynamic>)
          .map<ProstheticConfig>((item) => ProstheticConfig.fromJson(item))
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
