import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logicgame/editor/level_editor.dart';
import 'package:logicgame/game/game.dart';
import 'package:easy_localization/easy_localization.dart';

import 'level.dart';

import 'global_stats.dart' as stats;

late double previewSize;
late List<Level> levelsGlobal;
late int cIndex;

class LevelList extends StatelessWidget {
  final List<Level> levels;
  final bool isCampaign;
  final int index;

  const LevelList(
      {Key? key,
      required this.levels,
      required this.isCampaign,
      this.index = 0})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    cIndex = index;
    previewSize = MediaQuery.of(context).size.width / 6;
    levelsGlobal = levels;

    //TODO: remove after 2nd campaign is finished
    if (cIndex == 2) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.blueGrey[900],
                title: const Text(
                  'В разработке!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              );
            }).then((_) => Navigator.pop(context));
      });
    }

    return Container(
      color: Colors.black,
      child: ListView(
        children: makeLevelTabs(levels),
      ),
    );
  }

  bool checkIfUnlocked(Level l) {
    late int unlocked;
    switch (index) {
      case 1:
        unlocked = stats.c1Unlocked;
        break;
      case 2:
        unlocked = stats.c2Unlocked;
        break;
      default:
    }
    if (levelsGlobal.indexOf(l) > unlocked) {
      return false;
    } else {
      return true;
    }
  }

  makeLevelTabs(List<Level> l) {
    List<LevelTab> tabs = [];
    for (var _l in l) {
      var unlocked = true;
      if (isCampaign) {
        unlocked = checkIfUnlocked(_l);
      }

      tabs.add(LevelTab(
        level: _l,
        isCampaign: isCampaign,
        key: UniqueKey(),
        isUnlocked: unlocked,
      ));
    }
    return tabs;
  }
}

class LevelTab extends StatelessWidget {
  final Level level;
  final bool isCampaign;
  final bool isUnlocked;
  const LevelTab(
      {Key? key,
      required this.level,
      required this.isCampaign,
      this.isUnlocked = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    LevelEditor l;

    try {
      !isCampaign ? l = LevelEditor.level(level: level) : null;
    } catch (e) {
      Clipboard.setData(ClipboardData(text: e.toString()));

      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                backgroundColor: Colors.blueGrey[900],
                title: Text(
                  'Ошибка',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  e.toString(),
                  style: TextStyle(color: Colors.white),
                ));
          });
    }

    return Stack(children: [
      Material(
        color: Colors.blueGrey[900],
        child: InkWell(
          onTap: () {
            if (isUnlocked) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => isCampaign
                          ? CampaignGame(
                              levels: levelsGlobal,
                              levelIndex: levelsGlobal.indexOf(level),
                              campaignIndex: cIndex,
                            )
                          : LevelEditor.level(level: level)));
            }
          },
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    height: previewSize,
                    width: previewSize,
                    child: Center(
                      child: Preview(
                        level: level,
                        key: UniqueKey(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                      '${levelsGlobal.indexOf(level) + 1}. ${level.title.tr()}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 20)),
                ),
              ],
            )),
          ),
        ),
      ),
      !isUnlocked
          ? const Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: Material(
                  color: Colors.black,
                ),
              ),
            )
          : Container()
    ]);
  }
}

class Preview extends StatelessWidget {
  final Level level;
  const Preview({Key? key, required this.level}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = level.width;
    var height = level.height;
    var mobs = level.mobs;
    double size =
        width > height ? previewSize / (width + 1) : previewSize / (height + 1);
    List<Container> cells = List.generate(
        width * height,
        (i) => Container(
              color: Colors.blueGrey[900],
              width: size,
              height: size,
            ));
    for (var mob in mobs) {
      String literal = mob.keys.first;
      Point<int> coords = mob.values.first['position'];
      int linearCoords = coords.y * width + coords.x;
      Container impression;
      switch (literal) {
        case "arrowMob":
          impression = Container(
            color: Colors.blue[900],
            width: size,
            height: size,
          );
          break;
        case "border":
          if (mob.values.first['color'] == null) {
            impression = Container(
              color: Colors.black,
              width: size,
              height: size,
            );
            break;
          } else {
            switch (mob.values.first['color']) {
              case 1:
                impression = Container(
                  color: Colors.red[900],
                  width: size,
                  height: size,
                );
                break;
              case 2:
                impression = Container(
                  color: Colors.pink[900],
                  width: size,
                  height: size,
                );
                break;
              case 3:
                impression = Container(
                  color: Colors.purple[900],
                  width: size,
                  height: size,
                );
                break;
              case 4:
                impression = Container(
                  color: Colors.blue[900],
                  width: size,
                  height: size,
                );
                break;
              case 5:
                impression = Container(
                  color: Colors.cyan[900],
                  width: size,
                  height: size,
                );
                break;
              case 6:
                impression = Container(
                  color: Colors.green[900],
                  width: size,
                  height: size,
                );
                break;
              case 7:
                impression = Container(
                  color: Colors.yellow[900],
                  width: size,
                  height: size,
                );
                break;
              default:
                impression = Container(
                  color: Colors.black,
                  width: size,
                  height: size,
                );
                break;
            }
          }
          break;
        case "exit":
          impression = Container(
            color: Colors.green[900],
            width: size,
            height: size,
          );
          break;
        case "rotator":
          impression = Container(
            color: Colors.purple[900],
            width: size,
            height: size,
          );
          break;
        case "switcher":
          impression = Container(
            color: Colors.yellow,
            width: size,
            height: size,
          );
          break;

        case "info":
          impression = Container(
            color: Colors.white70,
            width: size,
            height: size,
          );
          break;
        default:
          impression = Container(
            color: Colors.amber,
            width: size,
            height: size,
          );
      }
      cells[linearCoords] = impression;
    }
    cells[level.playerPos.y * width + level.playerPos.x] = Container(
      color: Colors.red[900],
      width: size,
      height: size,
    );
    List<List<Container>> _cells = List.generate(height, (index) => []);
    for (var i = 0; i < height; i++) {
      for (var j = 0; j < width; j++) {
        _cells[i].add(cells[i * width + j]);
      }
    }
    return Padding(
      padding: EdgeInsets.all(size / 2),
      child: Center(
        child: SizedBox(
          width: width * size,
          height: height * size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                _cells.length,
                (i) => Row(
                      children: _cells[i],
                    )),
          ),
        ),
      ),
    );
  }
}
