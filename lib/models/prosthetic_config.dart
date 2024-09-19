import 'dart:convert';
import 'package:flutter/material.dart';

class ProstheticConfig {
  final String id;
  final double length;
  final double width;
  final Color color;
  final String modelPath;

  ProstheticConfig({
    required this.id,
    required this.length,
    required this.width,
    required this.color,
    required this.modelPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'length': length,
    'width': width,
    'color': color.value,
    'modelPath': modelPath,
  };

  factory ProstheticConfig.fromJson(Map<String, dynamic> json) => ProstheticConfig(
    id: json['id'],
    length: json['length'],
    width: json['width'],
    color: Color(json['color']),
    modelPath: json['modelPath'],
  );

  static String encode(List<ProstheticConfig> configs) => json.encode(
    configs.map((config) => config.toJson()).toList(),
  );

  static List<ProstheticConfig> decode(String configs) =>
    (json.decode(configs) as List<dynamic>)
      .map<ProstheticConfig>((item) => ProstheticConfig.fromJson(item))
      .toList();
}