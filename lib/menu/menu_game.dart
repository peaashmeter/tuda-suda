import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart' hide Border;
import 'package:flutter/material.dart' hide Border;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/scheduler.dart';
import 'package:logicgame/game/core.dart';

import 'package:logicgame/game/directions.dart';
import 'package:logicgame/game/entities.dart';
import 'package:logicgame/game/impressions.dart';

import 'package:logicgame/game/mobs.dart';
import 'package:logicgame/generator/generator.dart';

import 'dart:math';

import '../level.dart';

class MenuGame extends StatefulWidget {
  final Level level;
  const MenuGame({
    Key? key,
    required this.level,
  }) : super(key: key);

  @override
  State<MenuGame> createState() => _GameState();

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
}

class _GameState extends State<MenuGame> {
  late double xCellsOnScreen;
  late double yCellsOnScreen;

  ValueNotifier<bool> isOnPause = ValueNotifier(false);

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

    isDpad = false;
    level = widget.level;
    xCellsOnScreen = level.boardSize;
  }

  @override
  void didChangeDependencies() {
    cellSize = widget.getCellSize(context, xCellsOnScreen);
    yCellsOnScreen = widget.getYCellsOnScreen(level, context, xCellsOnScreen);

    core = Core(level, cellSize, nextLevel, replay, context,
        isPlayerInvincible: true);

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
        onVerticalDragEnd: isDpad
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
              title: Text(level.title.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
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
            bottomNavigationBar: isDpad
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
                child: Text('to_editor'.tr(),
                    style: TextStyle(color: Colors.blueGrey[50], fontSize: 20)),
              ),
            ],
          );
        });
  }

  void replay() {
    setState(() {
      level = generateLevel(isTimed: true, time: 1000);
      core = Core(level, cellSize, nextLevel, replay, context,
          isPlayerInvincible: true);

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
  }

  void nextLevel() {}
}
