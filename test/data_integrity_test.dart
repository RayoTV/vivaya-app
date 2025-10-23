import 'dart:convert';
import 'dart:io';

void main() async {
  final assetsDir = Directory('assets/data');
  if (!assetsDir.existsSync()) {
    print('❌ Validation failed: assets/data directory not found');
    exit(1);
  }

  // Helper to load JSON
  Map<String, dynamic> loadJsonFile(String name) {
    final f = File('${assetsDir.path}/$name');
    if (!f.existsSync()) {
      print('❌ Validation failed: $name missing');
      exit(1);
    }
    final txt = f.readAsStringSync();
    return json.decode(txt) as Map<String, dynamic>;
  }

  List<dynamic> loadJsonArray(String name) {
    final f = File('${assetsDir.path}/$name');
    if (!f.existsSync()) {
      print('❌ Validation failed: $name missing');
      exit(1);
    }
    final txt = f.readAsStringSync();
    return json.decode(txt) as List<dynamic>;
  }

  // Validate meals
  final gain = loadJsonArray('meals_gain.json');
  final loss = loadJsonArray('meals_loss.json');
  final maintain = loadJsonArray('meals_maintain.json');

  bool checkMealCounts(List<dynamic> list, String name) {
    final counts = {'breakfast':0,'lunch':0,'dinner':0,'snack':0,'drink':0};
    for (final it in list) {
      if (it is Map && it['type'] is String) {
        final t = it['type'] as String;
        if (counts.containsKey(t)) counts[t] = counts[t]! + 1;
      }
    }
    final ok = counts['breakfast']! >= 10 && counts['lunch']! >= 10 && counts['dinner']! >= 10 && counts['snack']! >= 8 && counts['drink']! >= 8;
    if (!ok) {
      print('❌ Validation failed: $name counts mismatch -> $counts');
    }
    return ok;
  }

  if (!checkMealCounts(gain,'meals_gain.json') || !checkMealCounts(loss,'meals_loss.json') || !checkMealCounts(maintain,'meals_maintain.json')) {
    exit(1);
  }

  // Exercises
  final exercises = loadJsonArray('exercises_home.json');
  if (exercises.length < 24) {
    print('❌ Validation failed: exercises_home.json count < 24 (${exercises.length})');
    exit(1);
  }

  // Notifications
  final notifications = loadJsonFile('notifications.json');
  final expectedCats = ['morning','pre_meal','post_workout','water','evening'];
  for (final c in expectedCats) {
    if (!notifications.containsKey(c)) {
      print('❌ Validation failed: notifications missing category $c');
      exit(1);
    }
    final cat = notifications[c];
    if (!(cat is Map)) {
      print('❌ Validation failed: notifications.$c invalid');
      exit(1);
    }
    final ar = cat['ar'] as List?;
    final en = cat['en'] as List?;
    if (ar==null || en==null || ar.length < 5 || en.length < 5) {
      print('❌ Validation failed: notifications.$c ar/en length < 5');
      exit(1);
    }
  }

  // program_rules keys
  final rules = loadJsonFile('program_rules.json');
  final requiredKeys = ['weekly_structure','filters','unit_settings'];
  for (final k in requiredKeys) {
    if (!rules.containsKey(k)) {
      print('❌ Validation failed: program_rules.json missing $k');
      exit(1);
    }
  }

  // Duplicate ID across all meals
  final ids = <String>{};
  for (final list in [gain,loss,maintain]) {
    for (final it in list) {
      if (it is Map) {
        final id = it['id'] as String?;
        if (id==null) {
          print('❌ Validation failed: missing id in meal');
          exit(1);
        }
        if (ids.contains(id)) {
          print('❌ Validation failed: duplicate id across meals $id');
          exit(1);
        }
        ids.add(id);
      }
    }
  }

  // kcal ranges
  for (final list in [gain,loss,maintain]) {
    for (final it in list) {
      if (it is Map) {
        final kcal = it['kcal'];
        if (kcal is int) {
          if (kcal < 100 || kcal > 850) {
            print('❌ Validation failed: kcal out of range for ${it['id']} -> $kcal');
            exit(1);
          }
        } else if (kcal is double) {
          if (kcal < 100.0 || kcal > 850.0) {
            print('❌ Validation failed: kcal out of range for ${it['id']} -> $kcal');
            exit(1);
          }
        } else {
          print('❌ Validation failed: kcal missing or invalid for ${it['id']}');
          exit(1);
        }
      }
    }
  }

  print('✅ All JSON assets valid and ready.');
  exit(0);
}
