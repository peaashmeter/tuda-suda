import 'package:flutter/material.dart';
import 'dart:math';

const int width = 4;
const int height = 8;

List<Mob> mobs = [
  Mob(Directions.right, 23),
  Mob(Directions.left, 14),
  Mob(Directions.bottom, 13)
];
Player playerInstance = Player(width * height - 4);
ValueNotifier<List<Cell>> cells = ValueNotifier(List.generate(
    width * height, (index) => const Cell(nearMobs: 0, nearPlayer: false)));

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Game(),
    );
  }
}

class Game extends StatefulWidget {
  const Game({
    Key? key,
  }) : super(key: key);

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  @override
  Widget build(BuildContext context) {
    buildCells();
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<List<Cell>>(
            valueListenable: cells,
            builder: (BuildContext context, List<Cell> value, Widget? child) {
              return GridView.count(
                crossAxisCount: 4,
                children: value,
              );
            }),
      ),
    );
  }

  void buildCells() {
    var updatedCells = List.generate(
        width * height, (index) => const Cell(nearMobs: 0, nearPlayer: false));
    var nearCells = <int>[];
    for (var mob in mobs) {
      nearCells.add(mob.calculateMove());
    }
    var set = nearCells.toSet();
    for (var n in set) {
      updatedCells[n] = Cell(
          nearMobs: nearCells.where((e) => e == n).length, nearPlayer: false);
    }
    for (var mob in mobs) {
      updatedCells[mob.pos] = const Cell.mob();
    }
    for (var n in playerInstance.findNearCells()) {
      updatedCells[n] =
          Cell(nearMobs: updatedCells[n].nearMobs, nearPlayer: true);
    }
    updatedCells[playerInstance.pos] = const Cell.player();

    cells.value = updatedCells;
  }
}

class Cell extends StatelessWidget {
  final int nearMobs;
  final bool nearPlayer;
  final bool player;
  final bool mob;

  const Cell({
    Key? key,
    required this.nearMobs,
    required this.nearPlayer,
    this.player = false,
    this.mob = false,
  }) : super(key: key);

  const Cell.player({
    Key? key,
    this.nearMobs = 0,
    this.nearPlayer = false,
    this.player = true,
    this.mob = false,
  }) : super(key: key);

  const Cell.mob({
    Key? key,
    this.nearMobs = 0,
    this.nearPlayer = false,
    this.player = false,
    this.mob = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          nearPlayer ? () => cells.value = updateCells(mobs, this) : () => {},
      child: Stack(
        children: _children(),
      ),
    );
  }

  _children() {
    return <Widget>[
      Container(color: Colors.blueGrey[900]),
      ...mob ? [_mob()] : [],
      ...player ? [_player()] : [],
      ...List.filled(nearMobs, _mobIndicator()),
      ...nearPlayer ? [_playerIndicator()] : [],
    ];
  }

  _mob() => Opacity(
      opacity: 1,
      child: Container(
        color: Colors.blue,
      ));
  _player() => Opacity(
      opacity: 1,
      child: Container(
        color: Colors.red,
      ));
  _mobIndicator() => Opacity(
      opacity: 0.25,
      child: Container(
        color: Colors.blue,
      ));
  _playerIndicator() => Opacity(
      opacity: 0.25,
      child: Container(
        color: Colors.red,
      ));
}

List<Cell> updateCells(List<Mob> mobs, Cell nextPlayerPos) {
  var updatedCells = List.generate(
      width * height, (index) => const Cell(nearMobs: 0, nearPlayer: false));
  var nearCells = <int>[];
  for (var mob in mobs) {
    mob.pos = mob.calculateMove();
    nearCells.add(mob.calculateMove());
  }
  var set = nearCells.toSet();
  for (var n in set) {
    updatedCells[n] = Cell(
        nearMobs: nearCells.where((e) => e == n).length, nearPlayer: false);
  }
  for (var mob in mobs) {
    updatedCells[mob.pos] = Cell.mob(nearMobs: updatedCells[mob.pos].nearMobs);
  }
  playerInstance.pos = cells.value.indexOf(nextPlayerPos);
  updatedCells[playerInstance.pos] = const Cell.player();
  for (var n in playerInstance.findNearCells()) {
    updatedCells[n] = Cell(
        mob: updatedCells[n].mob,
        nearMobs: updatedCells[n].nearMobs,
        nearPlayer: true);
  }

  return updatedCells;
}

class Player {
  int pos;
  Player(this.pos);

  List<int> findNearCells() {
    var cells = <int>[];
    //left
    if (pos % width == 0) {
      cells.add(pos + width - 1);
      cells.add(pos + 1);
    }
    //right
    else if ((pos + 1) % width == 0) {
      cells.add(pos - width + 1);
      cells.add(pos - 1);
    }
    //general case
    else {
      cells.add(pos - 1);
      cells.add(pos + 1);
    }

    //player can't clip through the top and bottom
    if (pos < width) {
      cells.add(pos + width);
    } else if (pos > width * height - width - 1) {
      cells.add(pos - width);
    } else {
      cells.add(pos + width);
      cells.add(pos - width);
    }
    return cells;
  }
}

enum Directions { left, top, right, bottom, zero }

class Mob {
  int pos;
  final Directions direction;
  Mob(this.direction, this.pos);

  int calculateMove() {
    switch (direction) {
      case Directions.left:
        if (pos % width == 0) {
          return pos + width - 1;
        } else {
          return pos - 1;
        }
      case Directions.right:
        if ((pos + 1) % width == 0) {
          return pos - (width - 1);
        } else {
          return pos + 1;
        }

      case Directions.top:
        if (pos < width) {
          return width * height - (width - pos % 4);
        } else {
          return pos - width;
        }
      case Directions.bottom:
        if (pos > width * height - width - 1) {
          return pos % width;
        } else {
          return pos + width;
        }
      default:
        return pos;
    }
  }
}
