import 'dart:async';

import 'package:flutter/material.dart' hide Border;
import 'package:easy_localization/easy_localization.dart';
import 'package:logicgame/game/core.dart';

import 'package:logicgame/settings.dart' as settings;
import 'package:logicgame/global_stats.dart' as stats;

import 'package:logicgame/campaign_list.dart';

import 'package:logicgame/storage/storage.dart';
import '../level.dart';
import 'directions.dart';

class CampaignGame extends StatefulWidget {
  final List<Level> levels;
  final int campaignIndex;
  final int levelIndex;
  const CampaignGame(
      {Key? key,
      required this.levels,
      required this.campaignIndex,
      required this.levelIndex})
      : super(key: key);

  @override
  State<CampaignGame> createState() => _GameState();

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

class _GameState extends State<CampaignGame> {
  late double xCellsOnScreen;
  late double yCellsOnScreen;

  ValueNotifier<bool> isOnPause = ValueNotifier(false);

  late int levelIndex;
  late Level level;

  late Core core;
  late Level levels;
  late double cellSize;
  late bool isDpad;

  late Board board;

  bool isDialogShown = false;

  ValueNotifier<Object> timer = ValueNotifier(Object);

  @override
  void initState() {
    super.initState();

    isDpad = settings.isDpad;
    levelIndex = widget.levelIndex;
    level = widget.levels[levelIndex];
    xCellsOnScreen = level.boardSize;
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

                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (globalContext) => const CampaignList()),
                      (r) => false);
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

  void nextLevel() {
    core.destroyBoard();

    if (levelIndex + 1 < widget.levels.length) {
      setState(() {
        isDialogShown = false;

        levelIndex++;
        level = widget.levels[levelIndex];
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
    } else if (!stats.c1Reward) {
      stats.c1Unlocked = 30;
      stats.c1Reward = true;
      stats.coins += 100;
      stats.charSkinsOwn[32] = 'true';

      stats.writeStats();

      showDialog(
          context: context,
          builder: (context) => const SkinDialog(
                1,
                "Кампания пройдена!",
                "В награду за прохождение вы получили 100 осколков и новый облик персонажа!",
              )).then((value) => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (globalContext) => const CampaignList()),
          (r) => false));
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (globalContext) => const CampaignList()),
          (r) => false);
    }

    unlockLevel(levelIndex);

    // isDialogShown = false;
    // Future.delayed(const Duration(milliseconds: 500)).then((value) {
    //   playerInstance = Player(levels[currentLevel.value].playerPos);
    //   if (currentLevel.value < levels.length - 1) {
    //     currentLevel.value = (currentLevel.value + 1);
    //     unlockLevel(currentLevel.value);
    //     makeBoard(currentLevel.value);
    //   } else {
    //     if (index == 1) {
    //       if (!stats.c1Reward) {
    //         stats.c1Unlocked = 30;
    //         stats.c1Reward = true;
    //         stats.coins += 100;
    //         stats.charSkinsOwn[32] = 'true';

    //         stats.writeStats();
    //         showDialog(
    //             context: globalContext,
    //             builder: (context) => const SkinDialog(
    //                   1,
    //                   "Кампания пройдена!",
    //                   "В награду за прохождение вы получили 100 осколков и новый облик персонажа!",
    //                 )).then((value) => Navigator.pushReplacement(
    //             globalContext,
    //             MaterialPageRoute(
    //                 builder: (globalContext) => const CampaignList())));
    //       } else {
    //         Navigator.pushReplacement(
    //             globalContext,
    //             MaterialPageRoute(
    //                 builder: (globalContext) => const CampaignList()));
    //       }
    //     }
    //   }
    // });
  }

  void unlockLevel(int l) {
    switch (widget.campaignIndex) {
      case 1:
        if (stats.c1Unlocked < l) {
          stats.c1Unlocked = l;
        }

        break;
      default:
    }
    stats.writeStats();
  }
}
