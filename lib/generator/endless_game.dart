import 'dart:async';

import 'package:flutter/material.dart' hide Border;
import 'package:easy_localization/easy_localization.dart';
import 'package:logicgame/game/core.dart';
import 'package:logicgame/game/directions.dart';
import 'package:logicgame/generator/endless_menu.dart';
import 'package:logicgame/generator/interlevel.dart';

import 'package:logicgame/settings.dart' as settings;
import 'package:logicgame/generator/endless_stats.dart' as stats;
import 'dart:math';

import '../level.dart';

class EndlessGame extends StatefulWidget {
  final Level level;
  final int levelScore;
  final int passed;
  final int totalScore;
  const EndlessGame({
    Key? key,
    required this.level,
    required this.levelScore,
    this.passed = 0,
    this.totalScore = 0,
  }) : super(key: key);

  @override
  State<EndlessGame> createState() => _GameState();

  double getCellSize(BuildContext context, double xCellsOnScreen) {
    var pixelWidth = MediaQuery.of(context).size.width / xCellsOnScreen;
    var pixelHeight = MediaQuery.of(context).size.height / xCellsOnScreen;
    return pixelWidth < pixelHeight ? pixelWidth : pixelHeight;
  }

  double getYCellsOnScreen(
      Level level, BuildContext context, double xCellsOnScreen) {
    return level.height <=
            1 / MediaQuery.of(context).size.aspectRatio * xCellsOnScreen - 2
        ? level.height.toDouble()
        : 1 / MediaQuery.of(context).size.aspectRatio * xCellsOnScreen - 2;
  }

  void movePlayer(Directions d, Core core) {
    if (core.playerInstance.isAlive) {
      switch (d) {
        case Directions.right:
          core.playerInstance.direction = Directions.right;
          core.playerInstance.makeTurn(
              const Point(1, 0),
              core.mobs,
              core.disposables,
              core.playerInstance,
              core.width,
              core.height,
              core.updateState);
          break;
        case Directions.down:
          core.playerInstance.direction = Directions.down;
          core.playerInstance.makeTurn(
              const Point(0, 1),
              core.mobs,
              core.disposables,
              core.playerInstance,
              core.width,
              core.height,
              core.updateState);
          break;

        case Directions.left:
          core.playerInstance.direction = Directions.left;
          core.playerInstance.makeTurn(
              const Point(-1, 0),
              core.mobs,
              core.disposables,
              core.playerInstance,
              core.width,
              core.height,
              core.updateState);
          break;

        case Directions.up:
          core.playerInstance.direction = Directions.up;
          core.playerInstance.makeTurn(
              const Point(0, -1),
              core.mobs,
              core.disposables,
              core.playerInstance,
              core.width,
              core.height,
              core.updateState);
          break;
        default:
      }
    }
  }
}

class _GameState extends State<EndlessGame> {
  late double xCellsOnScreen;
  late double yCellsOnScreen;

  ValueNotifier<bool> isOnPause = ValueNotifier(false);

  late ValueNotifier<int> healthNotfier;

  late Core core;
  late Level level;
  late double cellSize;
  late bool isDpad;

  late Board board;

  bool isDialogShown = false;

  ValueNotifier<Object> timer = ValueNotifier(Object);

  @override
  void initState() {
    super.initState();

    isDpad = settings.isDpad;
    level = widget.level;
    xCellsOnScreen = level.boardSize;

    healthNotfier = ValueNotifier(3);
  }

  @override
  void didChangeDependencies() {
    cellSize = widget.getCellSize(context, xCellsOnScreen);
    yCellsOnScreen = widget.getYCellsOnScreen(level, context, xCellsOnScreen);

    core = Core(level, cellSize, nextLevel, replay, context);

    board = Board(
      cellSize: cellSize,
      xCellsOnScreen: xCellsOnScreen,
      yCellsOnScreen: yCellsOnScreen,
      height: core.height,
      width: core.width,
      playerInstance: core.playerInstance,
      cellsNotifiers: core.cellsNotifiers,
      key: UniqueKey(),
    );
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onHorizontalDragEnd: isDpad
            ? null
            : (details) {
                var v = details.primaryVelocity;
                if (v != 0 && v != null) {
                  if (v > 0) {
                    core.movePlayer(Directions.right);
                  } else {
                    core.movePlayer(Directions.left);
                  }
                }
              },
        onVerticalDragEnd: settings.isDpad
            ? null
            : (details) {
                var v = details.primaryVelocity;
                if (v != 0 && v != null) {
                  if (v > 0) {
                    core.movePlayer(Directions.down);
                  } else {
                    core.movePlayer(Directions.up);
                  }
                }
              },
        child: WillPopScope(
          onWillPop: () async {
            isOnPause.value = true;
            return (showMenuDialog(context, level)
                .then((value) => isOnPause.value = false));
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.blueGrey[900],
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Случайный уровень ${widget.passed + 1}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                    ValueListenableBuilder(
                        valueListenable: healthNotfier,
                        builder: (context, int value, child) {
                          List<Widget> children = [];
                          for (var i = 0; i < value; i++) {
                            children.add(const Icon(
                              Icons.favorite_rounded,
                              color: Colors.red,
                            ));
                          }
                          while (children.length < 3) {
                            children.add(const Icon(
                              Icons.favorite_rounded,
                              color: Colors.black,
                            ));
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: children,
                          );
                        })
                  ]),
              actions: [
                IconButton(
                    onPressed: () {
                      isOnPause.value = true;
                      showMenuDialog(context, level)
                          .then((value) => isOnPause.value = false);
                    },
                    icon: const Icon(Icons.menu_rounded))
              ],
              flexibleSpace: SizedBox(
                height: cellSize * 2,
                child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ValueListenableBuilder(
                      valueListenable: playerNotifier,
                      builder: (context, value, child) {
                        return ValueListenableBuilder(
                            valueListenable: isOnPause,
                            builder: (BuildContext context, bool pause,
                                Widget? child) {
                              if (level.turnTime == 0 || isOnPause.value) {
                                return Container(
                                  height: 4,
                                  color: Colors.blueGrey[900],
                                );
                              }
                              return TimeIndicator(
                                key: UniqueKey(),
                                time: level.turnTime,
                                isKilling: level.deathTimer,
                                core: core,
                                replay: replay,
                                notifier: timer,
                              );
                            });
                      },
                    )),
              ),
            ),
            body: Container(
              color: Colors.black,
              child: Align(
                alignment: Alignment.center,
                child: Builder(builder: (context) {
                  WidgetsBinding.instance?.addPostFrameCallback((_) async {
                    if (!isDialogShown && level.dialog != '') {
                      isOnPause.value = true;
                      await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleDialog(
                              backgroundColor: Colors.blueGrey[900],
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(level.dialog.tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.blueGrey[50],
                                          fontSize: 20)),
                                ),
                              ],
                            );
                          }).then((value) => isOnPause.value = false);
                      isDialogShown = true;
                    }
                  });
                  return board;
                }),
              ),
            ),
            bottomNavigationBar: settings.isDpad
                ? BottomAppBar(
                    child: DPad(
                      cellSize: cellSize,
                      movePlayer: core.movePlayer,
                      core: core,
                    ),
                  )
                : null,
          ),
        ));
  }

  Future<dynamic> showMenuDialog(BuildContext context, Level level) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            backgroundColor: Colors.blueGrey[900],
            title: Text('pause'.tr(),
                style: TextStyle(color: Colors.blueGrey[50], fontSize: 30)),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  replay();
                  Navigator.pop(context);
                },
                child: Text('replay'.tr(),
                    style: TextStyle(color: Colors.blueGrey[50], fontSize: 20)),
              ),
              SimpleDialogOption(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          backgroundColor: Colors.blueGrey[900],
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(level.dialog.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.blueGrey[50],
                                      fontSize: 20)),
                            ),
                          ],
                        );
                      });
                },
                child: Text('show_dialog'.tr(),
                    style: TextStyle(color: Colors.blueGrey[50], fontSize: 20)),
              ),
              SimpleDialogOption(
                onPressed: () {
                  isDialogShown = false;

                  int count = 0;
                  Navigator.popUntil(context, (route) => count++ == 2);
                },
                child: Text('to_menu'.tr(),
                    style: TextStyle(color: Colors.blueGrey[50], fontSize: 20)),
              ),
            ],
          );
        });
  }

  void replay() {
    core.destroyBoard();

    healthNotfier.value--;
    if (healthNotfier.value == 0) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        setState(() {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (globalContext) => EndlessMenu(
                      maxRow: stats.maxRow,
                      highScore: stats.highScore,
                      levelsPassed: stats.levelsPassed)));
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        setState(() {
          core = Core(level, cellSize, nextLevel, replay, context);

          board = Board(
            cellSize: cellSize,
            xCellsOnScreen: xCellsOnScreen,
            yCellsOnScreen: yCellsOnScreen,
            height: core.height,
            width: core.width,
            playerInstance: core.playerInstance,
            cellsNotifiers: core.cellsNotifiers,
            key: UniqueKey(),
          );
        });
      });
    }
  }

  void nextLevel() {
    core.destroyBoard();
    isDialogShown = false;
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (globalContext) => Interlevel(
                  passed: widget.passed + 1,
                  levelScore: widget.levelScore,
                  totalScore: widget.totalScore,
                  health: healthNotfier.value,
                  coins: core.playerInstance.coins)));
    });
  }
}
