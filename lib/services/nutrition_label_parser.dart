class ParsedNutrition {
  const ParsedNutrition({
    this.name,
    this.servingLabel,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String? name;
  final String? servingLabel;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
}

enum _Nutrient {
  energy,
  fat,
  satFat,
  carbs,
  sugars,
  fiber,
  protein,
  salt,
}

class _Row {
  _Row(this.kind);
  final _Nutrient kind;
  final List<double> values = [];
}

class NutritionLabelParser {
  static final _servingSize = RegExp(
    r'serving\s*size\s*[:\-]?\s*(.+)$',
    caseSensitive: false,
    multiLine: true,
  );
  static final _portion = RegExp(
    r'(\d+\s*porsiyon\s*\([^)]+\))',
    caseSensitive: false,
  );
  static final _per100 = RegExp(
    r'(?:/\s*)?100\s*(ml|g)\b',
    caseSensitive: false,
  );

  static ParsedNutrition parse(String text) {
    final original = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final folded = _fold(original);
    final rows = _collectRows(folded);
    final columnCount = rows.fold<int>(
      0,
      (max, row) => row.values.length > max ? row.values.length : max,
    );
    final column = columnCount <= 1 ? 0 : columnCount - 1;
    final usedPortion = column > 0 && _portion.hasMatch(folded);

    return ParsedNutrition(
      servingLabel: _servingLabel(original, folded, usedPortion: usedPortion),
      calories: _pick(_values(rows, _Nutrient.energy), column),
      proteinG: _pick(_values(rows, _Nutrient.protein), column),
      carbsG: _pick(_values(rows, _Nutrient.carbs), column),
      fatG: _pick(_values(rows, _Nutrient.fat), column),
    );
  }

  static List<double> _values(List<_Row> rows, _Nutrient kind) {
    for (final row in rows) {
      if (row.kind == kind && row.values.isNotEmpty) {
        return row.values;
      }
    }
    return const [];
  }

  static double? _pick(List<double> values, int column) {
    if (values.isEmpty) return null;
    if (column >= values.length) return values.last;
    return values[column];
  }

  static String? _servingLabel(
    String original,
    String folded, {
    required bool usedPortion,
  }) {
    if (usedPortion) {
      final match = _portion.firstMatch(original) ?? _portion.firstMatch(folded);
      if (match != null) {
        return match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }

    final per100 = _per100.firstMatch(original) ?? _per100.firstMatch(folded);
    if (per100 != null) {
      return '100 ${per100.group(1)!.toLowerCase()}';
    }

    if (RegExp(
      r'(?:ogeleri|values)\s*/?\s*100\b',
      caseSensitive: false,
    ).hasMatch(folded)) {
      return '100 g';
    }

    final serving = _servingSize.firstMatch(original)?.group(1)?.trim();
    if (serving != null && serving.isNotEmpty) return serving;
    return null;
  }

  static List<_Row> _collectRows(String folded) {
    final rows = <_Row>[];
    final unmatched = <_Row>[];
    final valueBuf = <String>[];

    void flush() {
      _assignValues(unmatched, valueBuf);
      valueBuf.clear();
    }

    for (final rawLine in folded.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final kind = _labelKind(line);
      if (kind != null) {
        flush();
        final row = _Row(kind);
        final leftover = _stripLabel(line);
        row.values.addAll(_numbersFor(kind, leftover));
        rows.add(row);
        if (row.values.isEmpty) unmatched.add(row);
        continue;
      }

      if (_isValueLine(line)) {
        valueBuf.add(line);
        continue;
      }

      if (_isIgnorableNoise(line)) continue;

      flush();
    }
    flush();
    return rows;
  }

  static void _assignValues(List<_Row> unmatched, List<String> valueLines) {
    if (unmatched.isEmpty || valueLines.isEmpty) return;

    if (unmatched.length == 1) {
      final kind = unmatched.first.kind;
      for (final line in valueLines) {
        unmatched.first.values.addAll(
          kind == _Nutrient.energy
              ? _energyKcals(line, allowBareNumbers: false)
              : _numbersFor(kind, line),
        );
      }
      unmatched.clear();
      return;
    }

    if (valueLines.length == unmatched.length) {
      for (var i = 0; i < unmatched.length; i++) {
        unmatched[i].values.addAll(
          _numbersFor(unmatched[i].kind, valueLines[i]),
        );
      }
      unmatched.clear();
      return;
    }

    _Row? energy;
    for (final row in unmatched) {
      if (row.kind == _Nutrient.energy) {
        energy = row;
        break;
      }
    }
    if (energy == null) return;

    final energyValues = [
      for (final line in valueLines)
        ..._energyKcals(line, allowBareNumbers: false),
    ];
    if (energyValues.isEmpty) return;
    energy.values.addAll(energyValues);
    unmatched.remove(energy);
  }

  static List<double> _numbersFor(_Nutrient kind, String text) {
    if (text.trim().isEmpty) return const [];
    if (kind == _Nutrient.energy) return _energyKcals(text);
    return _grams(text);
  }

  static List<double> _energyKcals(
    String text, {
    bool allowBareNumbers = true,
  }) {
    final out = <double>[];

    void add(double? value) {
      if (value == null) return;
      out.add(value);
    }

    final kjKcal = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*kj\s*/\s*(\d+(?:[.,]\d+)?)\s*kcal',
      caseSensitive: false,
    );
    for (final match in kjKcal.allMatches(text)) {
      add(_parseNum(match.group(2)!));
    }

    final kcalThenKj = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*kcal\s*(?:\((?:[^)]*?)\))?',
      caseSensitive: false,
    );
    for (final match in kcalThenKj.allMatches(text)) {
      final value = _parseNum(match.group(1)!);
      if (value != null && !out.contains(value)) add(value);
    }

    final kcalAfter = RegExp(
      r'kcal\s*(\d+(?:[.,]\d+)?)(?!\d)(?!\s*kj)',
      caseSensitive: false,
    );
    for (final match in kcalAfter.allMatches(text)) {
      final value = _parseNum(match.group(1)!);
      if (value != null && !out.contains(value)) add(value);
    }

    if (out.isEmpty) {
      final slash = RegExp(r'(\d+(?:[.,]\d+)?)\s*/\s*(\d+(?:[.,]\d+)?)');
      for (final match in slash.allMatches(text)) {
        final kj = _parseNum(match.group(1)!);
        final kcal = _parseNum(match.group(2)!);
        if (kj == null || kcal == null || kcal <= 0) continue;
        final ratio = kj / kcal;
        if (ratio > 3.5 && ratio < 5.0) add(kcal);
      }
    }

    if (out.isEmpty) {
      final kjOnly = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*kj\b',
        caseSensitive: false,
      );
      for (final match in kjOnly.allMatches(text)) {
        add(_kjToKcal(_parseNum(match.group(1)!)));
      }
    }

    if (out.isEmpty &&
        allowBareNumbers &&
        !RegExp(r'kcal|\bkj\b', caseSensitive: false).hasMatch(text) &&
        !_per100.hasMatch(text) &&
        !_portion.hasMatch(text)) {
      out.addAll(_grams(text));
    }

    return out;
  }

  static List<double> _grams(String text) {
    final cut = text.split('%').first;
    final prefixed = RegExp(
      r'(?:^|[^a-z0-9])g\s+(\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    );
    final prefixedValues = [
      for (final match in prefixed.allMatches(cut))
        if (_parseNum(match.group(1)!) != null) _parseNum(match.group(1)!)!,
    ];
    if (prefixedValues.isNotEmpty) return prefixedValues;

    final suffixed = RegExp(
      r'<?\s*(\d+(?:[.,]\d+)?)\s*g\b',
      caseSensitive: false,
    );
    final suffixedValues = [
      for (final match in suffixed.allMatches(cut))
        if (_parseNum(match.group(1)!) != null) _parseNum(match.group(1)!)!,
    ];
    if (suffixedValues.isNotEmpty) return suffixedValues;

    return [
      for (final match in RegExp(r'<?\s*(\d+(?:[.,]\d+)?)').allMatches(cut))
        if (_parseNum(match.group(1)!) != null) _parseNum(match.group(1)!)!,
    ];
  }

  static _Nutrient? _labelKind(String line) {
    final l = line.toLowerCase();
    if (_isValueLine(line) && !RegExp(r'^[a-z]').hasMatch(l)) {
      return null;
    }
    if (RegExp(
      r'ogeleri|nutritional\s+values|nutrition\s+facts',
    ).hasMatch(l)) {
      return null;
    }
    if (RegExp(r'^enerj?i\s+ve\b').hasMatch(l) &&
        !RegExp(r'kcal|\bkj\b|\d').hasMatch(l)) {
      return null;
    }
    if (_startsWith(
      l,
      r'doymus|saturated|trans\s*fat|of which saturates',
    )) {
      return _Nutrient.satFat;
    }
    if (_startsWith(l, r'seker|sugars?\b|of which sugars')) {
      return _Nutrient.sugars;
    }
    if (_startsWith(l, r'lif\b|fiber\b|fibre\b')) {
      return _Nutrient.fiber;
    }
    if (_startsWith(l, r'tuz\b|salt\b')) {
      return _Nutrient.salt;
    }
    if (_startsWith(l, r'protein')) {
      return _Nutrient.protein;
    }
    if (_startsWith(l, r'karbonhidrat|(?:total\s+)?carb(?:ohydrate)?s?')) {
      return _Nutrient.carbs;
    }
    if (_startsWith(l, r'(?:total\s+)?fat\b|yag\b')) {
      return _Nutrient.fat;
    }
    if (_startsWith(l, r'enerj?i\b|energy\b|(?<!from\s)calories\b')) {
      return _Nutrient.energy;
    }
    return null;
  }

  static bool _startsWith(String line, String pattern) {
    return RegExp(
      '^[-–—•]*\\s*(?:$pattern)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static String _stripLabel(String line) {
    return line.replaceFirst(
      RegExp(
        r'^[-–—•]*\s*(?:enerj?i|energy|calories|total\s+fat|fat|yag|'
        r'karbonhidrat|carb(?:ohydrate)?s?|protein|doymus|saturated|'
        r'seker|sugars?|lif|fiber|fibre|tuz|salt)\b[:\-/]*',
        caseSensitive: false,
      ),
      '',
    );
  }

  static bool _isValueLine(String line) {
    if (RegExp(
      r'^(?:[<]?\d+(?:[.,]\d+)?\s*(?:g\b|kj\b|kcal\b|/)|[gk]j?\s+\d|kcal\b|j\s+\d)',
      caseSensitive: false,
    ).hasMatch(line)) {
      return true;
    }
    return RegExp(
      r'^[<]?\d+(?:[.,]\d+)?(?:\s*/\s*\d+(?:[.,]\d+)?)?\s*$',
    ).hasMatch(line);
  }

  static bool _isIgnorableNoise(String line) {
    final cyrillic = RegExp(r'[\u0400-\u04FF]').allMatches(line).length;
    final compact = line.replaceAll(' ', '');
    return cyrillic >= 4 && compact.isNotEmpty && cyrillic * 2 >= compact.length;
  }

  static String _fold(String text) {
    var folded = text
        .replaceAll('\u0130', 'I')
        .replaceAll('\u0131', 'i')
        .replaceAll('\u00C7', 'C')
        .replaceAll('\u00E7', 'c')
        .replaceAll('\u011E', 'G')
        .replaceAll('\u011F', 'g')
        .replaceAll('\u00D6', 'O')
        .replaceAll('\u00F6', 'o')
        .replaceAll('\u015E', 'S')
        .replaceAll('\u015F', 's')
        .replaceAll('\u00DC', 'U')
        .replaceAll('\u00FC', 'u');
    folded = folded.replaceAllMapped(
      RegExp(r'[ÌÍÎÏ]'),
      (_) => 'I',
    );
    folded = folded.replaceAllMapped(
      RegExp(r'[ìíîï]'),
      (_) => 'i',
    );
    return folded;
  }

  static double? _parseNum(String raw) {
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  static double? _kjToKcal(double? kj) {
    if (kj == null) return null;
    return double.parse((kj / 4.184).toStringAsFixed(1));
  }
}
