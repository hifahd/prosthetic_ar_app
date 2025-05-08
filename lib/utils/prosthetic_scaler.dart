class ProstheticScaler {
  /// Calculate scale factors based on patient age and limb type
  static Map<String, double> getScaleFactorsForAge(int age, String limbType) {
    // Default scaling factor
    double scaleFactor = 1.0;

    // Age-based scaling with more precise values
    if (age < 6) {
      scaleFactor = 0.5; // Children under 6
    } else if (age >= 6 && age < 12) {
      scaleFactor = 0.7; // Children 6-11
    } else if (age >= 12 && age < 18) {
      scaleFactor = 0.85; // Teenagers
    } else if (age >= 18 && age < 30) {
      scaleFactor = 1.0; // Young adults
    } else if (age >= 30 && age < 65) {
      scaleFactor = 0.98; // Adults
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
      dimensionFactors['y'] =
          scaleFactor * 1.1; // Arms are longer relative to width
      dimensionFactors['x'] = scaleFactor * 0.9; // Arms are thinner
    } else if (limbType.toLowerCase().contains("leg")) {
      dimensionFactors['y'] = scaleFactor * 1.2; // Legs are longer
      dimensionFactors['x'] =
          scaleFactor * 0.95; // Legs are slightly thinner than the default
    } else if (limbType.toLowerCase().contains("hand")) {
      dimensionFactors['y'] = scaleFactor * 0.8; // Hands are smaller in height
      dimensionFactors['x'] = scaleFactor * 0.8; // Hands are smaller in width
    } else if (limbType.toLowerCase().contains("foot")) {
      dimensionFactors['y'] = scaleFactor * 0.7; // Feet are smaller in height
      dimensionFactors['x'] = scaleFactor * 1.1; // Feet are wider
    }

    return dimensionFactors;
  }

  /// Extracts limb type from model path
  static String getLimbTypeFromModelPath(String modelPath) {
    final filename = modelPath.split('/').last.toLowerCase();

    if (filename.contains("arm") ||
        filename.contains("hand") ||
        filename.contains("elbow") ||
        filename.contains("wrist")) {
      return "arm";
    } else if (filename.contains("leg") ||
        filename.contains("foot") ||
        filename.contains("knee") ||
        filename.contains("ankle")) {
      return "leg";
    } else if (filename.contains("cyborg")) {
      return "hand"; // Special case for Cyborg Beast model
    } else {
      return "generic";
    }
  }
}
