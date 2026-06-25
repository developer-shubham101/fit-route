class UnitsUtil {
  static const double _lbPerKg = 2.20462262185;

  static double toKg(double value, String units) {
    if (units == 'imperial') {
      return value / _lbPerKg;
    }
    return value; // metric
  }

  static double fromKg(double kg, String units) {
    if (units == 'imperial') {
      return kg * _lbPerKg;
    }
    return kg; // metric
  }

  static String unitLabel(String units) => units == 'imperial' ? 'lb' : 'kg';

  static String formatWeight(double? kg, String units) {
    if (kg == null) return '';
    final v = fromKg(kg, units);
    final label = unitLabel(units);
    return '${v.toStringAsFixed(0)} $label';
  }
}
