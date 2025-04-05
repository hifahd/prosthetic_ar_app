class ProstheticScaler {
  /// Calculate scale factors based on patient age and limb type
  static Map<String, double> getScaleFactorsForAge(int age, String limbType) {
    // Default scaling factor
    double scaleFactor = 1.0;

    // Age-based scaling
    if (age < 6) {
      scaleFactor = 0.5; // Children under 6
    } else if (age >= 6 && age < 12) {
      scaleFactor = 0.7; // Children 6-11
    } else if (age >= 12 && age < 18) {
      scaleFactor = 0.85; // Teenagers
    } else if (age >= 65) {
      scaleFactor = 0.95; // Seniors
    }

    // Different scale factors for different dimensions
    Map<String, double> dimensionFactors = {
      'x': scaleFactor,
      'y': scaleFactor,
      'z': scaleFactor,
    };

    // Limb-specific adjustments
    if (limbType.toLowerCase().contains("arm")) {
      double currentY =
          dimensionFactors['y'] ?? scaleFactor; // Use null-safe access
      dimensionFactors['y'] =
          currentY * 1.1; // Arms are longer relative to width
    } else if (limbType.toLowerCase().contains("leg")) {
      double currentZ =
          dimensionFactors['z'] ?? scaleFactor; // Use null-safe access
      dimensionFactors['z'] =
          currentZ * 0.9; // Legs may need adjustment in depth
    }

    return dimensionFactors;
  }

  /// Extracts limb type from model path
  static String getLimbTypeFromModelPath(String modelPath) {
    final filename = modelPath.split('/').last.toLowerCase();

    if (filename.contains("arm") || filename.contains("hand")) {
      return "arm";
    } else if (filename.contains("leg") || filename.contains("foot")) {
      return "leg";
    } else {
      return "generic";
    }
  }
}
