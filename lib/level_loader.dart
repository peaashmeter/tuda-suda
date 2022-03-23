import 'dart:convert';

import 'package:flutter/services.dart';

import 'level.dart';

const String path = 'assets/data/levels';

Future<List<Level>> loadLevels(int index) async {
  List<Level> levels = [];
  String levelsString =
      await rootBundle.loadString('assets/data/levels$index.json');
  List levelsJson = jsonDecode(levelsString);

  for (var level in levelsJson) {
    levels.add(Level.fromJson(level));
  }
  return levels;
}
