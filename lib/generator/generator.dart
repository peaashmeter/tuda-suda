import 'dart:math';

import 'package:logicgame/game/directions.dart';
import 'package:logicgame/game/mob_handler.dart';
import 'package:logicgame/game/mobs.dart';
import 'package:logicgame/generator/patterns.dart';

import '../level.dart';

int levelScore = 0;

Level generateLevel({int difficulty = 0, bool isTimed = false, int time = 0}) {
  //var doGenerateCoin = true;
  //print(doGenerateCoin);
  // Point<int> start = Point(0, height - 1);
  // Point<int> end = Point(width - 1, 0);
  // Point<int>? coin = null;
  // List<Point<int>> noMobCells = [];

  var patternGenerators = getPatternGenerators();

  var size = getSize(difficulty);
  var width = size[0];
  var height = size[1];
  // var width = 7;
  // var height = 7;

  //testing
  // var _l = {};
  // difficulty = 100;
  // var size = getSize(difficulty);
  //var width = size[0];
  //var height = size[1];
  // for (var i = 0; i < 10000; i++) {
  //   for (var generator in patternGenerators.entries) {
  //     print(generator.key);
  //     if (generator.key(width, height, <Pattern>[])) {
  //       var p = generator.value == difficulty
  //           ? 1.0
  //           : (1 / (difficulty - generator.value)).abs();
  //       _l.addAll({generator.key: p});
  //     }
  //   }
  // }

  Map<Function, double> generators = {};
  for (var generator in patternGenerators.entries) {
    print(generator.key);
    if (generator.key(width, height, <Pattern>[])) {
      var p = generator.value == difficulty
          ? 1.0
          : (1 / (difficulty - generator.value)).abs();
      generators.addAll({generator.key: p});
    }
  }
  print('difficulty: $difficulty');
  //print(generators);

  List<Pattern> _pattern = [];

  double totalWeight =
      generators.values.fold(0, (prev, element) => prev + element);
  double rand = Random().nextDouble() * totalWeight;
  double s = 0;
  for (var p in generators.entries) {
    s += p.value;
    if (s >= rand) {
      if (p.key(width, height, _pattern)) {
        break;
      }
    }
  }
  var pattern = _pattern.first;
  List<Mob> mobs = [];

  mobs.addAll(pattern.mobs);
  //print(pattern.path.toSet().difference(pattern.idealPath.toSet()));
  //print('path: ${pattern.path}, idealPath: ${pattern.idealPath}');
  // List<Border> borders = [];
  // var path = _pathTrace(start, end, coin, width, height);
  // if (coin != null) {
  //   var coinBounds = addCoinNest(path, mobs, coin, width, height);
  //   var coinBoundsCoords = coinBounds.map((e) => e.position);
  //   mobs.addAll(coinBounds);
  //   noMobCells.addAll(coinBoundsCoords);
  //   noMobCells.add(coin);
  //   borders.addAll(coinBounds.whereType<Border>());
  // }

  print(pattern.path); //ключ к прохождению
  mobs.addAll(_addBorders(pattern.path, pattern.idealPath, width, height));
  // borders.addAll(_addBorders(path, noMobCells, width, height));
  // mobs.addAll(borders);
  // var bordersCoords = borders.map((e) => e.position);
  // noMobCells.addAll(bordersCoords);

  var _mobs = _addMobs(pattern.path, mobs, width, height, difficulty);
  var coins = _addCoins(pattern.path, mobs);
  mobs.addAll(_mobs);
  mobs.addAll(coins);
  mobs.add(Exit(mobs.length, pattern.path.last));

  var isTimer = false;
  if (difficulty > 4) {
    var r = Random().nextInt(3);
    if (r == 2) {
      isTimer = true;
    }
  }
  levelScore = countLevelScore(pattern.path, mobs, true);

  return Level(
      height: height,
      width: width,
      playerPos: pattern.path.first,
      turnTime: isTimer
          ? 3000
          : isTimed
              ? time
              : 0,
      mobs: encodeMobs(mobs),
      title: 'Случайный уровень');
}

int countLevelScore(List<Point<int>> path, List<Mob> mobs, bool isTimer) {
  int score = 0;
  score += path.length * 10;
  score += mobs.whereType<ArrowMob>().length * 5;
  score += mobs.whereType<TimedDoor>().length * 50;
  score += mobs.whereType<Annihilator>().length * 20;
  isTimer ? score += 100 : () {};
  return score;
}

List<int> getSize(int difficulty) {
  int size;
  if (difficulty < 5) {
    size = 4;
  } else if (difficulty < 9) {
    size = 5;
  } else if (difficulty < 14) {
    size = 7;
  } else {
    size = 9;
  }

  var x = Random().nextInt(4) + size;
  var y = (size + 1) + (size + 1 - x);
  return [x, y];
}

int _countDistance(Point<int> a, Point<int> b) {
  return (b.x - a.x).abs() + (b.y - a.y).abs();
}

List<Border> _addBorders(
    List<Point<int>> path, List<Point<int>> idealPath, int width, int height) {
  // List<Point<int>> cells =
  //     List.generate(width * height, (x) => Point<int>(x % width, x ~/ width));
  // List<Point<int>> availableCells =
  //     cells.toSet().difference((path + forbidden).toSet()).toList();
  List<Point<int>> availableCells =
      idealPath.toSet().difference(path.toSet()).toList();
  int count = availableCells.length < (width * height) ~/ 6
      ? availableCells.length
      : (width * height) ~/ 6;
  List<Border> borders = [];
  for (var i = 0; i < count; i++) {
    Point<int> pos = availableCells[Random().nextInt(availableCells.length)];
    borders.add(Border(i, pos));
    availableCells.remove(pos);
  }
  return borders;
}

List<Mob> _addMobs(List<Point<int>> path, List<Mob> mobs, int width, int height,
    int difficulty) {
  List<Point<int>> cells =
      List.generate(width * height, (x) => Point<int>(x % width, x ~/ width))
          .where((point) => _countDistance(path.first, point) % 2 == 0)
          .toList();
  List<Bound> borders = mobs.whereType<Bound>().toList();
  //borders.addAll(mobs.whereType<TimedDoor>());

  var bordersPos = borders.map((e) => e.position);
  List<Point<int>> availableCells =
      cells.toSet().difference(bordersPos.toSet()).toList();
  const _min = 0.4;
  const _max = 0.9;
  double _diff = max(min(_min, difficulty / 15), _max);
  int count = (((width * height) / 3) * _diff).round();
  List<Mob> genMobs = [];
  for (var i = 0; i < availableCells.length; i++) {
    for (var j = 0; j < 4; j++) {
      var mob = ArrowMob(mobs.length + genMobs.length, availableCells[i],
          Directions.values[j], height, width);
      var passed = false;
      var intersect = false;
      for (var k = 0; k < path.length; k++) {
        for (var t in borders.where((b) => b is! Annihilator)) {
          t.action(Player(path.first), []);
        }
        if (path.contains(mob.position)) {
          intersect = true;
        }
        if (mob.position == path[k]) {
          borders.whereType<TimedDoor>().forEach((element) {
            element.turns = path.length - 1;
            element.isOn = false;
          });
          break;
        } else if (mobs
            .whereType<Portal>()
            .where((p) => p.position == mob.position)
            .isNotEmpty) {
          var portal = mobs
              .whereType<Portal>()
              .where((p) => p.position == mob.position)
              .first;
          mob.position = Point(
              mob.position.x + portal.xShift, mob.position.y + portal.yShift);
        } else {
          mob.position = mob.getNextPosition(width, height, borders);
        }

        if (k == path.length - 1) {
          passed = true;
        }
        borders.whereType<TimedDoor>().forEach((element) {
          element.turns = path.length - 1;
          element.isOn = false;
        });
      }
      if (passed && intersect) {
        genMobs.add(ArrowMob(mobs.length + genMobs.length, availableCells[i],
            Directions.values[j], height, width));
      }
    }
  }
  genMobs.removeWhere((m) => m is Disposable);

  List<Mob> _mobs = [];

  for (var i = 0; i < count; i++) {
    if (genMobs.isNotEmpty) {
      var mob = genMobs[Random().nextInt(genMobs.length)];
      _mobs.add(mob);
      genMobs.remove(mob);
    }
  }
  return _mobs;
}

List<Coin> _addCoins(List<Point<int>> path, List<Mob> mobs) {
  List<Coin> coins = [];
  var pathMiddle = path.length ~/ 2;
  var availableCells = [];
  for (var i = pathMiddle; i < path.length - 1; i++) {
    availableCells.add(path[i]);
  }
  availableCells.toSet().toList();

  var count = availableCells.length ~/ 3;
  for (var i = 0; i < count; i++) {
    if (availableCells.isNotEmpty) {
      var n = Random().nextInt(availableCells.length);
      coins.add(Coin(mobs.length + coins.length, availableCells[n],
          Random().nextDouble() * pi / 3));
      availableCells.removeAt(n);
    } else {
      break;
    }
  }
  return coins;
}
