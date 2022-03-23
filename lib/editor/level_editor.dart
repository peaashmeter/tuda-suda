// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unnecessary_const

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import 'package:logicgame/storage/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

import 'package:logicgame/editor/editor_level_list.dart';
import 'package:logicgame/game/directions.dart';
import 'package:logicgame/game/impressions.dart';
import 'package:logicgame/game/mob_handler.dart';
import 'package:logicgame/game/mobs.dart' hide Border;
import 'package:logicgame/game/mobs.dart' as mob_class;

import 'package:logicgame/global_stats.dart' as stats;
import 'editor_game.dart' as game;
import '../level.dart';

int height = 4;
int width = 4;

ValueNotifier<bool> buildBoard = ValueNotifier(false);

ValueNotifier<Mob?> selectedMob = ValueNotifier(null);
ValueNotifier<bool> isTuning = ValueNotifier(false);
ValueNotifier<bool> isDeleting = ValueNotifier(false);
ValueNotifier<bool> isCopying = ValueNotifier(false);
ValueNotifier<int> currentLayer = ValueNotifier(0);
//Impression? selectedWidgetImpression;

//Emitter? tuningStart;

int id = 0;

List<List<Cell>> cells = List.generate(height, (index) => []);
List<Mob> mobs = [];
Map<Point<int>, List<Mob?>> mobsAsMap = {};

Point<int>? playerPos;
String title = 'Unnamed';
int turnTime = 0;
String dialog = '';
int turns = 0;
bool deathTimer = false;
double boardSize = 7.0;

String? titleAtLoad;

ValueNotifier<String> json = ValueNotifier('');

List<Map<Point<int>, List<Mob?>>> changeHistory = [];
ValueNotifier<int> historyPointer = ValueNotifier(0);

class LevelEditor extends StatefulWidget {
  LevelEditor({Key? key}) : super(key: key) {
    title = 'Unnamed';
    turnTime = 0;
    dialog = '';
    turns = 0;
    deathTimer = false;
    boardSize = 7.0;
  }
  LevelEditor.level({Key? key, required Level level}) : super(key: key) {
    height = level.height;
    width = level.width;
    mobs = decodeMobs(level.mobs, width, height);
    mobsAsMap = mobListToMap(mobs);
    changeHistory = [Map<Point<int>, List<Mob?>>.from(mobsAsMap)];
    historyPointer = ValueNotifier(0);
    playerPos = level.playerPos;
    mobsAsMap[playerPos]![0] = Player(playerPos!);
    title = level.title;
    turnTime = level.turnTime;
    dialog = level.dialog;
    turns = level.turns;
    isTuning.value = false;
    deathTimer = level.deathTimer;
    boardSize = level.boardSize;
    //tuningStart = null;
    cells = List.generate(height, (index) => []);
    titleAtLoad = level.title;
    id = mobs.length;
  }

  @override
  State<LevelEditor> createState() => _LevelEditorState();
}

class _LevelEditorState extends State<LevelEditor> {
  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: UniqueKey(),
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[900],
          title: ValueListenableBuilder<bool>(
              valueListenable: buildBoard,
              builder: (BuildContext context, bool built, Widget? child) {
                return Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                );
              }),
          actions: [
            IconButton(
                onPressed: () {
                  var _level = _createLevelFromScratch();
                  var _json = _level.toJson();
                  //json.value = jsonEncode(_json);
                  var level = Level.fromJson(_json);

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => game.EditorGame(level: level)));
                },
                icon: const Icon(Icons.play_arrow_rounded)),
            IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          backgroundColor: Colors.blueGrey[900],
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: ParametersForm(),
                            )
                          ],
                        );
                      });
                },
                icon: const Icon(Icons.settings_rounded)),
            IconButton(
                onPressed: () {
                  _saveLevel(context);
                },
                icon: const Icon(Icons.save_rounded)),
            IconButton(
              onPressed: () {
                _reallyDeleteDialog(context);
              },
              icon: const Icon(Icons.delete_rounded),
              color: Colors.red,
            )
          ],
          leading: IconButton(
              onPressed: () {
                _getCodeDialog(context);
              },
              icon: const Icon(Icons.code_rounded)),
        ),
        //Deprecated
        // drawer: Drawer(
        //   child: Column(
        //     children: [
        //       ParametersForm(formKey: _formKey),
        //       Padding(
        //         padding: const EdgeInsets.symmetric(vertical: 16.0),
        //         child: ElevatedButton(
        //           onPressed: () {
        //             var level = Level(
        //                 width: width,
        //                 height: height,
        //                 playerPos: playerPos ?? const Point(0, 0),
        //                 mobs: encodeMobs(mobs),
        //                 dialog: dialog,
        //                 title: title);
        //             var _json = level.toJson();
        //             json.value = jsonEncode(_json);
        //             Clipboard.setData(ClipboardData(text: json.value));
        //           },
        //           child: const Text('Save'),
        //         ),
        //       ),
        //       ValueListenableBuilder<String>(
        //           valueListenable: json,
        //           builder: (BuildContext context, String value, Widget? child) {
        //             return TextField(
        //               maxLines: null,
        //               controller: TextEditingController(text: value),
        //             );
        //           }),
        //     ],
        //   ),
        // ),

        body: Builder(builder: (context) {
          return Container(
              color: Colors.black,
              child: ValueListenableBuilder<bool>(
                  valueListenable: buildBoard,
                  builder: (BuildContext context, bool built, Widget? child) {
                    //extending mobsmap
                    Map<Point<int>, List<Mob?>> _map = {};
                    for (var x = 0; x < width; x++) {
                      for (var y = 0; y < height; y++) {
                        _map.addAll({
                          Point<int>(x, y): List.generate(16, (index) => null)
                        });
                      }
                    }
                    for (var e in mobsAsMap.entries) {
                      _map[e.key] = e.value;
                    }
                    mobsAsMap = _map;

                    return Board(
                      key: UniqueKey(),
                    );
                  }));
        }),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            color: Colors.blueGrey[900],
            height: getCellSize() * 2 + 16,
            child: Column(
              children: const [
                UtilityPanel(),
                TilePanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _getCodeDialog(BuildContext context) {
    var level = _createLevelFromScratch();
    var json = jsonEncode(level.toJson());
    var code = base64.encode(utf8.encode(json));

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.blueGrey[900],
            title: const Text(
              'Скопировать код уровня в буфер обмена',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            content: Text(code,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            actions: [
              Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.code_rounded),
                          label: const Text(
                            'Скопировать',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          )),
                      ElevatedButton.icon(
                          onPressed: () async {
                            Directory tempDir = await getTemporaryDirectory();
                            String tempPath = tempDir.path;
                            var txt = File('$tempPath/level.txt');
                            txt.writeAsStringSync(code);
                            Share.shareFiles(['$tempPath/level.txt']);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.share_rounded),
                          label: const Text(
                            'Отправить',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          )),
                    ]),
              )
            ],
          );
        });

    //if (stats.charSkinsOwn[23] == 'false') {

    //}
  }

  Level _createLevelFromScratch() {
    mobsAsMap.removeWhere((key, value) => key.x >= width || key.y >= height);
    for (var l in mobsAsMap.values) {
      if (l.whereType<Player>().isNotEmpty) {
        playerPos = l.whereType<Player>().first.position;
        break;
      }
    }
    mobs = mobMapToList(mobsAsMap);
    return Level(
        width: width,
        height: height,
        playerPos: playerPos ?? const Point(0, 0),
        mobs: encodeMobs(mobs),
        dialog: dialog,
        turnTime: turnTime,
        deathTimer: deathTimer,
        title: title,
        boardSize: boardSize);
  }

  void _reallyDeleteDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.blueGrey[900],
            title: const Text(
              'Уведомление',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            content: const Text('Вы действительно хотите удалить уровень?',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            actions: [
              Center(
                child: ElevatedButton.icon(
                    onPressed: () {
                      _deleteLevel(context);
                    },
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    label: const Text(
                      'Удалить',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    )),
              )
            ],
          );
        });
  }

  void _deleteLevel(BuildContext context) {
    var level = _createLevelFromScratch();
    if (List.generate(createdLevels.length, (l) => createdLevels[l].title)
        .contains(level.title)) {
      for (var i = 0; i < createdLevels.length; i++) {
        if (createdLevels[i].title == level.title) {
          createdLevels.removeAt(i);

          List<Map<String, dynamic>> levels = [];
          for (var _l in createdLevels) {
            levels.add(_l.toJson());
          }
          String levelsJson = jsonEncode(levels);
          writeJson(levelsJson);
          break;
        }
      }
    }
    decodeLevels().then((levels) => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const EditorLevelList()),
        (r) => false));
  }

  void _saveLevel(BuildContext context) {
    bool secret = false;

    if (List.generate(createdLevels.length, (l) => createdLevels[l].title)
        .contains(title)) {
      for (var i = 0; i < createdLevels.length; i++) {
        if (createdLevels[i].title == title) {
          createdLevels[i] = _createLevelFromScratch();

          List<Map<String, dynamic>> levels = [];
          for (var _l in createdLevels) {
            levels.add(_l.toJson());
          }
          String levelsJson = jsonEncode(levels);
          writeJson(levelsJson);
          break;
        }
      }
    } else {
      if (createdLevels
          .where((level) => level.title == titleAtLoad)
          .isNotEmpty) {
        createdLevels.remove(
            createdLevels.firstWhere((level) => level.title == titleAtLoad));
        title = makeProperLevelTitle(title);
      }

      var level = _createLevelFromScratch();
      //creeper secret
      if (level.title == 'Minecraft' &&
          level.width == 8 &&
          level.height == 8 &&
          level.mobs.where((mob) => mob.containsKey('border')).length == 20 &&
          level.mobs.where((mob) => mob.containsKey('exit')).length == 44) {
        if (stats.charSkinsOwn[23] == 'false') {
          secret = true;
          stats.charSkinsOwn[23] = 'true';
          stats.writeStats();
        }
      }

      createdLevels.add(level);
      List<Map<String, dynamic>> levels = [];
      for (var _l in createdLevels) {
        levels.add(_l.toJson());
      }
      String levelsJson = jsonEncode(levels);

      writeJson(levelsJson);
    }
    if (secret) {
      showDialog(
          context: context,
          builder: (BuildContext context) => SkinDialog(
              23, 'secret_found'.tr(), 'secret8'.tr())).then((value) =>
          decodeLevels().then((levels) => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const EditorLevelList()),
              (r) => false)));
    } else {
      decodeLevels().then((levels) => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const EditorLevelList()),
          (r) => false));
    }
  }
}

class TuningButton extends StatefulWidget {
  const TuningButton({Key? key}) : super(key: key);

  @override
  State<TuningButton> createState() => _TuningButtonState();
}

class _TuningButtonState extends State<TuningButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isTuning,
        builder: (context, bool tuning, child) {
          return IconButton(
            onPressed: () {
              selectedMob.value = null;

              isTuning.value = !isTuning.value;
              isDeleting.value = false;
              isCopying.value = false;
            },
            color: Colors.blueGrey[900],
            iconSize: 32,
            icon: Icon(
              Icons.build_rounded,
              color: tuning ? Colors.green : Colors.white70,
            ),
          );
        });
  }
}

class EydropperButton extends StatefulWidget {
  const EydropperButton({Key? key}) : super(key: key);

  @override
  State<EydropperButton> createState() => _EydropperButtonState();
}

class _EydropperButtonState extends State<EydropperButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isCopying,
        builder: (context, bool tuning, child) {
          return IconButton(
            onPressed: () {
              selectedMob.value = null;

              isCopying.value = !isCopying.value;
              isDeleting.value = false;
              isTuning.value = false;
            },
            color: Colors.blueGrey[900],
            iconSize: 32,
            icon: Icon(
              Icons.colorize_rounded,
              color: tuning ? Colors.green : Colors.white70,
            ),
          );
        });
  }
}

class DeletingButton extends StatelessWidget {
  const DeletingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: isDeleting,
        builder: (context, bool deleting, child) {
          return IconButton(
            onPressed: () {
              selectedMob.value = null;
              isTuning.value = false;
              isDeleting.value = !isDeleting.value;
              isCopying.value = false;
            },
            color: Colors.blueGrey[900],
            iconSize: 32,
            icon: Icon(
              Icons.clear_rounded,
              color: deleting ? Colors.red : Colors.white70,
            ),
          );
        });
  }
}

class ParametersForm extends StatefulWidget {
  const ParametersForm({Key? key}) : super(key: key);

  @override
  State<ParametersForm> createState() => _ParametersFormState();
}

class _ParametersFormState extends State<ParametersForm> {
  final _formKey = GlobalKey<FormState>();
  bool deathTimer_ = deathTimer;
  double boardWidth = boardSize;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        initialValue: title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                            labelText: 'editor_title'.tr(),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )),
                        onSaved: (value) => title = value ?? 'Unnamed',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              validator: (value) {
                                var w = int.tryParse(value!) ?? 0;
                                if (w < 1 || w > 1024) {
                                  return 'Ошибка';
                                }
                                return null;
                              },
                              initialValue: width.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  labelText: 'editor_width'.tr(),
                                  labelStyle: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              onSaved: (value) =>
                                  width = int.tryParse(value!) ?? 4,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              validator: (value) {
                                var w = int.tryParse(value!) ?? 0;
                                if (w < 1 || w > 1024) {
                                  return 'Ошибка';
                                }
                                return null;
                              },
                              initialValue: height.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                              decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  labelText: 'editor_height'.tr(),
                                  labelStyle: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              onSaved: (value) =>
                                  height = int.tryParse(value!) ?? 4,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'board_width'.tr(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                          Slider(
                              value: boardWidth,
                              min: 4.0,
                              max: 10.0,
                              divisions: 12,
                              label: boardWidth.toString(),
                              onChanged: (value) {
                                setState(() {
                                  setState(() {
                                    boardWidth = value;
                                  });
                                });
                              }),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        validator: (value) {
                          var w = ((double.tryParse(
                                      value?.replaceAll(',', '.') ?? '0') ??
                                  0) *
                              1000);
                          if (w < 0 || (w != 0 && w < 300)) {
                            return 'Ошибка';
                          }
                          return null;
                        },
                        initialValue: turnTime == 0
                            ? '0'
                            : (turnTime.toDouble() / 1000).toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                            labelText: 'Время на ход (сек)',
                            labelStyle:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        onSaved: (value) => turnTime = ((double.tryParse(
                                        value?.replaceAll(',', '.') ?? '0') ??
                                    0) *
                                1000)
                            .toInt(),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text('Хардкор:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              deathTimer_ = !deathTimer_;
                            });
                            deathTimer = deathTimer_;
                          },
                          child: deathTimer_
                              ? const Text('Вкл')
                              : const Text('Выкл'),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        initialValue: dialog,
                        maxLines: 5,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                            labelText: 'editor_dialog'.tr(),
                            labelStyle: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                        onSaved: (value) => dialog = value ?? 'dialog',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TextFormField(
            //     onSaved: (value) => turnTime = int.tryParse(value!) ?? 0,
            //     keyboardType: TextInputType.number,
            //     decoration: const InputDecoration(hintText: 'turnTime')),

            // TextFormField(
            //     onSaved: (value) => turns = int.tryParse(value!) ?? 0,
            //     keyboardType: TextInputType.number,
            //     decoration: const InputDecoration(hintText: 'turns')),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    boardSize = boardWidth;

                    buildBoard.value = !buildBoard.value;

                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class TimedDoorForm extends StatefulWidget {
  final TimedDoor mob;
  const TimedDoorForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<TimedDoorForm> createState() => _TimedDoorFormState();
}

class _TimedDoorFormState extends State<TimedDoorForm> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                validator: (value) {
                  if ((int.tryParse(value!) ?? 0) < 1) {
                    return 'Ошибка';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                initialValue: widget.mob.turns.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Таймер',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                onSaved: (value) =>
                    widget.mob.turns = int.tryParse(value ?? '1') ?? 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.connectedTo.isNotEmpty
                      ? widget.mob.connectedTo.first.toString() != '-1'
                          ? widget.mob.connectedTo.first.toString()
                          : ''
                      : '',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Соединение',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  onSaved: (value) {
                    if (value != '' && widget.mob.connectedTo.isNotEmpty) {
                      widget.mob.connectedTo[0] = int.parse(value!);
                      return;
                    } else if (value != '') {
                      widget.mob.connectedTo.add(int.parse(value!));
                    }
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    buildBoard.value = !buildBoard.value;
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class AnnihilatorForm extends StatefulWidget {
  final Annihilator mob;
  const AnnihilatorForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<AnnihilatorForm> createState() => _AnnihilatorFormState();
}

class _AnnihilatorFormState extends State<AnnihilatorForm> {
  final _formKey = GlobalKey<FormState>();
  late Directions direction;
  @override
  void initState() {
    direction = widget.mob.direction;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                validator: (value) {
                  if ((int.tryParse(value!) ?? 0) < 1) {
                    return 'Ошибка';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                initialValue: widget.mob.turns.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Перезарядка',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                onSaved: (value) =>
                    widget.mob.turns = int.tryParse(value ?? '1') ?? 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                validator: (value) {
                  if ((int.tryParse(value!) ?? -1) < 0) {
                    return 'Ошибка';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                initialValue: widget.mob.charge.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Заряд',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                onSaved: (value) =>
                    widget.mob.charge = int.tryParse(value ?? '1') ?? 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.connectedTo.isNotEmpty
                      ? widget.mob.connectedTo.first.toString() != '-1'
                          ? widget.mob.connectedTo.first.toString()
                          : ''
                      : '',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Соединение',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  onSaved: (value) {
                    if (value != '' && widget.mob.connectedTo.isNotEmpty) {
                      widget.mob.connectedTo[0] = int.parse(value!);
                      return;
                    } else if (value != '') {
                      widget.mob.connectedTo.add(int.parse(value!));
                    }
                  }),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                value: direction,
                dropdownColor: Colors.blueGrey[900],
                decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Направление',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                items: const [
                  DropdownMenuItem<Directions>(
                      value: Directions.left,
                      child: Text(
                        'Налево',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.up,
                      child: Text(
                        'Вверх',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.right,
                      child: Text(
                        'Направо',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.down,
                      child: Text(
                        'Вниз',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                ],
                onChanged: (Directions? newDir) {
                  direction = newDir ?? direction;
                },
                onSaved: (newValue) {
                  widget.mob.direction = direction;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    buildBoard.value = !buildBoard.value;
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class RepeaterForm extends StatefulWidget {
  final Repeater mob;
  const RepeaterForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<RepeaterForm> createState() => _RepeaterFormState();
}

class _RepeaterFormState extends State<RepeaterForm> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                validator: (value) {
                  if ((int.tryParse(value!) ?? 0) < 1) {
                    return 'Ошибка';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                initialValue: widget.mob.repeat.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Повторения',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                onSaved: (value) =>
                    widget.mob.repeat = int.tryParse(value ?? '1') ?? 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.connectedTo.isNotEmpty
                      ? widget.mob.connectedTo.first.toString() != '-1'
                          ? widget.mob.connectedTo.first.toString()
                          : ''
                      : '',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Соединение',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  onSaved: (value) {
                    if (value != '' && widget.mob.connectedTo.isNotEmpty) {
                      widget.mob.connectedTo[0] = int.parse(value!);
                      return;
                    } else if (value != '') {
                      widget.mob.connectedTo.add(int.parse(value!));
                    }
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    buildBoard.value = !buildBoard.value;
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class InfoForm extends StatefulWidget {
  final Info mob;
  const InfoForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<InfoForm> createState() => _InfoFormState();
}

class _InfoFormState extends State<InfoForm> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                maxLines: 5,
                validator: (value) {
                  return null;
                },
                keyboardType: TextInputType.multiline,
                initialValue: widget.mob.dialog.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Диалог',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                onSaved: (value) => widget.mob.dialog = value ?? '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class GateForm extends StatefulWidget {
  final Gate mob;
  const GateForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<GateForm> createState() => _GateFormState();
}

class _GateFormState extends State<GateForm> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class ArrowMobForm extends StatefulWidget {
  final ArrowMob mob;
  const ArrowMobForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<ArrowMobForm> createState() => _ArrowMobFormState();
}

class _ArrowMobFormState extends State<ArrowMobForm> {
  final _formKey = GlobalKey<FormState>();
  late Directions direction;

  @override
  void initState() {
    super.initState();
    direction = widget.mob.direction;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                value: direction,
                dropdownColor: Colors.blueGrey[900],
                decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Направление',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                items: const [
                  DropdownMenuItem<Directions>(
                      value: Directions.left,
                      child: Text(
                        'Налево',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.up,
                      child: Text(
                        'Вверх',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.right,
                      child: Text(
                        'Направо',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.down,
                      child: Text(
                        'Вниз',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                ],
                onChanged: (Directions? newDir) {
                  direction = newDir ?? direction;
                },
                onSaved: (newValue) {
                  widget.mob.direction = direction;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class RotatorForm extends StatefulWidget {
  final Rotator mob;
  const RotatorForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<RotatorForm> createState() => _RotatorFormState();
}

class _RotatorFormState extends State<RotatorForm> {
  final _formKey = GlobalKey<FormState>();
  late Directions direction;

  @override
  void initState() {
    super.initState();
    direction = widget.mob.direction;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                value: direction,
                dropdownColor: Colors.blueGrey[900],
                decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Направление',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                items: const [
                  DropdownMenuItem<Directions>(
                      value: Directions.left,
                      child: Text(
                        'Налево',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.up,
                      child: Text(
                        'Вверх',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.right,
                      child: Text(
                        'Направо',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<Directions>(
                      value: Directions.down,
                      child: Text(
                        'Вниз',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )),
                ],
                onChanged: (Directions? newDir) {
                  direction = newDir ?? direction;
                },
                onSaved: (newValue) {
                  widget.mob.direction = direction;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class BorderForm extends StatefulWidget {
  final mob_class.Border mob;
  const BorderForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<BorderForm> createState() => _BorderFormState();
}

class _BorderFormState extends State<BorderForm> {
  final _formKey = GlobalKey<FormState>();
  late int color;

  @override
  void initState() {
    super.initState();
    color = widget.mob.color;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  validator: (value) {
                    if ((int.tryParse(value!) ?? 0) < 1) {
                      return 'Ошибка';
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                  },
                  keyboardType: TextInputType.number,
                  initialValue: widget.mob.id.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      labelText: 'Id',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                value: color,
                dropdownColor: Colors.blueGrey,
                decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Цвет',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                items: [
                  const DropdownMenuItem<int>(
                      value: 0,
                      child: const Text(
                        'Чёрный',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 1,
                      child: Text(
                        'Красный',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 2,
                      child: Text(
                        'Розовый',
                        style: TextStyle(
                          color: Colors.pink[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 3,
                      child: Text(
                        'Фиолетовый',
                        style: TextStyle(
                          color: Colors.purple[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 4,
                      child: Text(
                        'Синий',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 5,
                      child: Text(
                        'Циан',
                        style: TextStyle(
                          color: Colors.cyan[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 6,
                      child: Text(
                        'Зелёный',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 7,
                      child: Text(
                        'Оранжевый',
                        style: TextStyle(
                          color: Colors.yellow[900],
                          fontSize: 16,
                        ),
                      )),
                ],
                onChanged: (int? newcolor) {
                  color = newcolor ?? color;
                },
                onSaved: (newValue) {
                  widget.mob.color = color;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class SwitcherForm extends StatefulWidget {
  final Switcher mob;
  const SwitcherForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<SwitcherForm> createState() => _SwitcherFormState();
}

class _SwitcherFormState extends State<SwitcherForm> {
  final _formKey = GlobalKey<FormState>();
  bool isOn = false;
  late int fields;

  @override
  void initState() {
    isOn = widget.mob.isOn;
    fields = widget.mob.connectedTo.isEmpty ? 1 : widget.mob.connectedTo.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 200,
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 100,
                        child: TextFormField(
                          validator: (value) {
                            if ((int.tryParse(value!) ?? 0) < 1) {
                              return 'Ошибка';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                          },
                          keyboardType: TextInputType.number,
                          initialValue: widget.mob.id.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              labelText: 'Id',
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                        ),
                      ),
                    ),
                    ...List.generate(
                      fields,
                      (index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: widget.mob.connectedTo.length > index
                                ? widget.mob.connectedTo[index].toString() !=
                                        '-1'
                                    ? widget.mob.connectedTo[index].toString()
                                    : ''
                                : '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                labelText: 'Соединение ${index + 1}',
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                )),
                            onSaved: (value) {
                              if (value != '' &&
                                  widget.mob.connectedTo.length > index) {
                                widget.mob.connectedTo[index] =
                                    int.parse(value!);
                                return;
                              } else if (value != '') {
                                widget.mob.connectedTo.add(int.parse(value!));
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('Cостояние:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isOn = !isOn;
                    });
                  },
                  child: isOn ? const Text('Вкл') : const Text('Выкл'),
                ),
              ],
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    fields++;
                  });
                },
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white70,
                  size: 32,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    widget.mob.isOn = isOn;

                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class PortalForm extends StatefulWidget {
  final Portal mob;
  const PortalForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<PortalForm> createState() => _PortalFormState();
}

class _PortalFormState extends State<PortalForm> {
  final _formKey = GlobalKey<FormState>();
  bool isOn = false;
  late int fields;
  late int color;

  @override
  void initState() {
    isOn = widget.mob.isOn;
    fields = widget.mob.connectedTo.isEmpty ? 1 : widget.mob.connectedTo.length;
    color = widget.mob.color;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 200,
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 100,
                        child: TextFormField(
                          validator: (value) {
                            if ((int.tryParse(value!) ?? 0) < 1) {
                              return 'Ошибка';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                          },
                          keyboardType: TextInputType.number,
                          initialValue: widget.mob.id.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              labelText: 'Id',
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                        ),
                      ),
                    ),
                    ...List.generate(
                      fields,
                      (index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: widget.mob.connectedTo.length > index
                                ? widget.mob.connectedTo[index].toString() !=
                                        '-1'
                                    ? widget.mob.connectedTo[index].toString()
                                    : ''
                                : '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                labelText: 'Соединение ${index + 1}',
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                )),
                            onSaved: (value) {
                              if (value != '' &&
                                  widget.mob.connectedTo.length > index) {
                                widget.mob.connectedTo[index] =
                                    int.parse(value!);
                                return;
                              } else if (value != '') {
                                widget.mob.connectedTo.add(int.parse(value!));
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                value: color,
                dropdownColor: Colors.blueGrey,
                decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Цвет',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                items: [
                  const DropdownMenuItem<int>(
                      value: 0,
                      child: Text(
                        'Чёрный',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 1,
                      child: Text(
                        'Красный',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 2,
                      child: Text(
                        'Розовый',
                        style: TextStyle(
                          color: Colors.pink[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 3,
                      child: Text(
                        'Фиолетовый',
                        style: TextStyle(
                          color: Colors.purple[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 4,
                      child: Text(
                        'Синий',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 5,
                      child: Text(
                        'Циан',
                        style: TextStyle(
                          color: Colors.cyan[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 6,
                      child: Text(
                        'Зелёный',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 16,
                        ),
                      )),
                  DropdownMenuItem<int>(
                      value: 7,
                      child: Text(
                        'Оранжевый',
                        style: TextStyle(
                          color: Colors.yellow[900],
                          fontSize: 16,
                        ),
                      )),
                ],
                onChanged: (int? newcolor) {
                  color = newcolor ?? color;
                },
                onSaved: (newValue) {
                  widget.mob.color = color;
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 100,
                    child: TextFormField(
                      validator: (value) {
                        if ((int.tryParse(value!) ?? 0) +
                                    widget.mob.position.x >=
                                width ||
                            (int.tryParse(value) ?? 0) + widget.mob.position.x <
                                0) {
                          return 'Ошибка';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        widget.mob.xShift =
                            int.tryParse(newValue ?? '0') ?? widget.mob.xShift;
                      },
                      keyboardType: TextInputType.number,
                      initialValue: widget.mob.xShift.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          labelText: 'Сдвиг по x',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          )),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 100,
                    child: TextFormField(
                      validator: (value) {
                        if ((int.tryParse(value!) ?? 0) +
                                    widget.mob.position.y >=
                                height ||
                            (int.tryParse(value) ?? 0) + widget.mob.position.y <
                                0) {
                          return 'Ошибка';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        widget.mob.yShift =
                            int.tryParse(newValue ?? '0') ?? widget.mob.yShift;
                      },
                      keyboardType: TextInputType.number,
                      initialValue: widget.mob.yShift.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          labelText: 'Сдвиг по y',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          )),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('Cостояние:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isOn = !isOn;
                    });
                  },
                  child: isOn ? const Text('Вкл') : const Text('Выкл'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    widget.mob.isOn = isOn;

                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class WireForm extends StatefulWidget {
  final Wire mob;
  const WireForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<WireForm> createState() => _WireFormState();
}

class _WireFormState extends State<WireForm> {
  final _formKey = GlobalKey<FormState>();
  late int fields;

  @override
  void initState() {
    fields = widget.mob.connectedTo.isEmpty ? 1 : widget.mob.connectedTo.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 200,
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 100,
                        child: TextFormField(
                          validator: (value) {
                            if ((int.tryParse(value!) ?? 0) < 1) {
                              return 'Ошибка';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                          },
                          keyboardType: TextInputType.number,
                          initialValue: widget.mob.id.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              labelText: 'Id',
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                        ),
                      ),
                    ),
                    ...List.generate(
                      fields,
                      (index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: widget.mob.connectedTo.length > index
                                ? widget.mob.connectedTo[index].toString() !=
                                        '-1'
                                    ? widget.mob.connectedTo[index].toString()
                                    : ''
                                : '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                labelText: 'Соединение ${index + 1}',
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                )),
                            onSaved: (value) {
                              if (value != '' &&
                                  widget.mob.connectedTo.length > index) {
                                widget.mob.connectedTo[index] =
                                    int.parse(value!);
                                return;
                              } else if (value != '') {
                                widget.mob.connectedTo.add(int.parse(value!));
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    fields++;
                  });
                },
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white70,
                  size: 32,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class ActivatorForm extends StatefulWidget {
  final Pressure mob;
  const ActivatorForm({Key? key, required this.mob}) : super(key: key);

  @override
  State<ActivatorForm> createState() => _ActivatorFormState();
}

class _ActivatorFormState extends State<ActivatorForm> {
  final _formKey = GlobalKey<FormState>();
  late int fields;

  @override
  void initState() {
    fields = widget.mob.connectedTo.isEmpty ? 1 : widget.mob.connectedTo.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 200,
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 100,
                        child: TextFormField(
                          validator: (value) {
                            if ((int.tryParse(value!) ?? 0) < 1) {
                              return 'Ошибка';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            widget.mob.id = int.tryParse(newValue ?? '1') ?? id;
                          },
                          keyboardType: TextInputType.number,
                          initialValue: widget.mob.id.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              labelText: 'Id',
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                        ),
                      ),
                    ),
                    ...List.generate(
                      fields,
                      (index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: widget.mob.connectedTo.length > index
                                ? widget.mob.connectedTo[index].toString() !=
                                        '-1'
                                    ? widget.mob.connectedTo[index].toString()
                                    : ''
                                : '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                labelText: 'Соединение ${index + 1}',
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                )),
                            onSaved: (value) {
                              if (value != '' &&
                                  widget.mob.connectedTo.length > index) {
                                widget.mob.connectedTo[index] =
                                    int.parse(value!);
                                return;
                              } else if (value != '') {
                                widget.mob.connectedTo.add(int.parse(value!));
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    fields++;
                  });
                },
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white70,
                  size: 32,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    currentLayer.notifyListeners();
                    Navigator.pop(context);
                  }
                },
                child: Text('editor_save'.tr()),
              ),
            )
          ],
        ));
  }
}

class UtilityPanel extends StatelessWidget {
  const UtilityPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getCellSize(),
      color: Colors.blueGrey[900]!.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          ActionButtons(),
          TuningButton(),
          DeletingButton(),
          EydropperButton(),
          LayerChanger()
        ],
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  const ActionButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [BackButton(), ForthButton()],
    );
  }
}

class BackButton extends StatefulWidget {
  const BackButton({Key? key}) : super(key: key);

  @override
  State<BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<BackButton> {
  bool isActive = true;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: historyPointer,
        builder: (context, int value, child) {
          if (historyPointer.value == 0) {
            isActive = false;
          } else {
            isActive = true;
          }
          return IconButton(
              onPressed: () {
                if (isActive) {
                  historyPointer.value--;
                  mobsAsMap = newMobMap(changeHistory[historyPointer.value]);
                  currentLayer.notifyListeners();
                }
              },
              icon: Icon(
                Icons.undo_rounded,
                color: isActive ? Colors.white70 : Colors.white30,
              ));
        });
  }
}

class ForthButton extends StatefulWidget {
  const ForthButton({Key? key}) : super(key: key);

  @override
  State<ForthButton> createState() => _ForthButtonState();
}

class _ForthButtonState extends State<ForthButton> {
  bool isActive = true;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: historyPointer,
        builder: (context, int value, child) {
          if (historyPointer.value == changeHistory.length - 1) {
            isActive = false;
          } else {
            isActive = true;
          }

          return IconButton(
              onPressed: () {
                if (isActive) {
                  historyPointer.value++;
                  mobsAsMap = newMobMap(changeHistory[historyPointer.value]);

                  currentLayer.notifyListeners();
                }
              },
              icon: Icon(
                Icons.redo_rounded,
                color: isActive ? Colors.white70 : Colors.white30,
              ));
        });
  }
}

class LayerChanger extends StatelessWidget {
  const LayerChanger({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () {
              if (currentLayer.value > 0) {
                currentLayer.value--;
              }
            },
            icon: Transform.rotate(
              angle: pi,
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: Colors.white70,
              ),
            )),
        ValueListenableBuilder<int>(
            valueListenable: currentLayer,
            builder: (BuildContext context, int layer, Widget? child) {
              return Text(
                '$layer',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              );
            }),
        IconButton(
            onPressed: () {
              if (currentLayer.value < 15) {
                currentLayer.value++;
              }
            },
            icon: const Icon(Icons.play_arrow_rounded,
                size: 32, color: Colors.white70)),
      ],
    );
  }
}

class TilePanel extends StatelessWidget {
  const TilePanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getCellSize() + 16,
      color: Colors.blueGrey[900],
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          TilePanelItem(mob: Player(const Point<int>(0, 0))),
          TilePanelItem(mob: Exit(0, const Point<int>(0, 0))),
          TilePanelItem(
            mob: mob_class.Border(1, const Point<int>(0, 0)),
          ),
          TilePanelItem(
            mob: ArrowMob(2, const Point<int>(0, 0), Directions.right, 0, 0,
                isAnimated: false),
          ),
          TilePanelItem(
              mob: Rotator(3, const Point<int>(0, 0), Directions.right,
                  isAnimated: false)),
          TilePanelItem(mob: Switcher(4, const Point<int>(0, 0), [], false)),
          TilePanelItem(mob: Gate(5, const Point<int>(0, 0), true)),
          TilePanelItem(mob: TimedDoor(6, const Point<int>(0, 0), 1, [])),
          TilePanelItem(mob: Info(7, const Point<int>(0, 0), '')),
          TilePanelItem(mob: Repeater(8, const Point<int>(0, 0), [], 1)),
          TilePanelItem(
            mob: Annihilator(
              9,
              const Point<int>(0, 0),
              Directions.right,
              1,
              4,
              [],
            ),
          ),
          TilePanelItem(mob: Wire(10, const Point<int>(0, 0), [])),
          TilePanelItem(mob: Pressure(11, const Point<int>(0, 0), [])),
          TilePanelItem(mob: Portal(12, const Point<int>(0, 0), [], true)),
        ],
      ),
    );
  }
}

class TilePanelItem extends StatefulWidget {
  final Mob mob;

  const TilePanelItem({Key? key, required this.mob}) : super(key: key);

  @override
  State<TilePanelItem> createState() => _TilePanelItemState();
}

class _TilePanelItemState extends State<TilePanelItem> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Mob?>(
        valueListenable: selectedMob,
        builder: (BuildContext context, Mob? selected, Widget? child) {
          return GestureDetector(
              onTap: _onTap,
              child: widget.mob != selected
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 4,
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        width: getCellSize(),
                        height: getCellSize(),
                        child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            child: widget.mob.getImpression(getCellSize())),
                        key: UniqueKey(),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: getCellSize(),
                        height: getCellSize(),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.greenAccent)),
                        child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            child: widget.mob.getImpression(getCellSize())),
                        key: UniqueKey(),
                      ),
                    ));
        });
  }

  _onTap() {
    isDeleting.value = false;
    isTuning.value = false;
    isCopying.value = false;
    if (selectedMob.value != widget.mob) {
      selectedMob.value = widget.mob;
    } else if (widget.mob.direction != Directions.zero) {
      switch (widget.mob.direction) {
        case Directions.left:
          setState(() {
            widget.mob.direction = Directions.up;
          });
          break;
        case Directions.up:
          setState(() {
            widget.mob.direction = Directions.right;
          });
          break;
        case Directions.right:
          setState(() {
            widget.mob.direction = Directions.down;
          });
          break;
        case Directions.down:
          setState(() {
            widget.mob.direction = Directions.left;
          });
          break;
        default:
      }
    } else if (widget.mob is TimedDoor) {
      setState(() {
        if ((widget.mob as TimedDoor).turns == 16) {
          (widget.mob as TimedDoor).turns = 1;
        } else {
          (widget.mob as TimedDoor).turns++;
        }
      });
    } else if (widget.mob is mob_class.Border) {
      setState(() {
        if ((widget.mob as mob_class.Border).color == 7) {
          (widget.mob as mob_class.Border).color = 0;
        } else {
          (widget.mob as mob_class.Border).color++;
        }
      });
    }
  }
}

class Board extends StatefulWidget {
  const Board({Key? key}) : super(key: key);

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  late LinkedScrollControllerGroup _controllers;
  late List<ScrollController> horizontalControllers = [];
  late ScrollController verticalController;
  @override
  initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    for (var i = 0; i < height; i++) {
      horizontalControllers.add(_controllers.addAndGet());
    }
    verticalController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
        valueListenable: currentLayer,
        builder: (BuildContext context, int layer, Widget? child) {
          cells = List.generate(
              height,
              (row) => List.generate(
                  width,
                  (i) => Cell(
                      key: UniqueKey(),
                      child: mobsAsMap[Point(i, row)]?[layer]
                          ?.getImpression(getCellSize()),
                      x: i,
                      y: row)));

          // for (var i = 0; i < _cells.length; i++) {
          //   for (var j = 0; j < _cells[0].length; j++) {
          //     cells[i][j] = _cells[i][j];
          //   }
          // }
          // if (playerPos != null) {
          //   cells[playerPos!.y][playerPos!.x] = Cell(
          //       key: UniqueKey(),
          //       child: Player(playerPos!).getImpression(getCellSize()),
          //       x: playerPos!.x,
          //       y: playerPos!.y);
          // }

          List<Widget> rows = [];
          for (int k = 0; k < cells.length; k++) {
            var row = cells[k];
            var r = Center(
                child: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ListView(
                    shrinkWrap: true,
                    controller: horizontalControllers[k],
                    scrollDirection: Axis.horizontal,
                    children: row),
              ),
            ));
            rows.add(r);
          }
          return ScrollConfiguration(
            behavior: DragBehavior(),
            child: ListView(
                padding: const EdgeInsets.all(0.0),
                controller: verticalController,
                shrinkWrap: false,
                children: rows),
          );
        });
  }
}

class DragBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class Cell extends StatefulWidget {
  final Widget? child;
  final int x;
  final int y;

  const Cell({Key? key, required this.child, required this.x, required this.y})
      : super(key: key);

  @override
  State<Cell> createState() => _CellState();
}

class _CellState extends State<Cell> with AutomaticKeepAliveClientMixin {
  late Widget? _child = widget.child;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        var map = newMobMap(mobsAsMap);
        setState(() {
          if (isTuning.value) {
            var mobInCell = map[Point(widget.x, widget.y)]?[currentLayer.value];
            if (mobInCell is TimedDoor) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TimedDoorForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Info) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InfoForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Gate) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GateForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Switcher) {
              // isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SwitcherForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is mob_class.Border) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: BorderForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Rotator) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RotatorForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Repeater) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RepeaterForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Annihilator) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnnihilatorForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Wire) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: WireForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Pressure) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ActivatorForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is Portal) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: PortalForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            } else if (mobInCell is ArrowMob) {
              //isTuning.value = false;
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return SimpleDialog(
                      backgroundColor: Colors.blueGrey[900],
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ArrowMobForm(mob: mobInCell),
                        )
                      ],
                    );
                  }).then((value) {
                if (value != null) {
                  makeChange(map);
                }
              });
            }
          } else if (isCopying.value) {
            Point<int> pos = Point(widget.x, widget.y);
            if (map[pos]?[currentLayer.value] != null) {
              selectedMob.value = cloneMob(map[pos]![currentLayer.value]!, pos);
              isCopying.value = false;
            }
          } else if (isDeleting.value) {
            Point<int> pos = Point(widget.x, widget.y);
            map[pos]?[currentLayer.value] = null;
            _child = null;
            cells[widget.y][widget.x] =
                Cell(child: _child, x: widget.x, y: widget.y);
            makeChange(map);
            // } else if (isCopying.value) {
            //   Point<int> pos = Point(widget.x, widget.y);
            //   if (map[pos]?[currentLayer.value] != null) {
            //     selectedMob.value = cloneMob(map[pos]![currentLayer.value]!, pos);
            //     isCopying.value = false;
            //   }
          } else if (selectedMob.value != null) {
            cells[widget.y][widget.x] =
                Cell(child: _child, x: widget.x, y: widget.y);

            _child = selectedMob.value!.getImpression(getCellSize());
            selectedMob.value!.position = Point<int>(widget.x, widget.y);
            map[Point<int>(widget.x, widget.y)]![currentLayer.value] =
                cloneMob(selectedMob.value!, selectedMob.value!.position);
            if (selectedMob.value is Player) {
              for (var p in map.entries) {
                if (p.key != Point<int>(widget.x, widget.y)) {
                  if (p.value[currentLayer.value] is Player) {
                    p.value[currentLayer.value] = null;
                  }
                }
              }

              currentLayer.notifyListeners();
            }
            makeChange(map);
          }
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
              ),
              child: _child,
            ),
          ),
        ),
      ),
    );
  }
}

Map<Point<int>, List<Mob?>> newMobMap(Map<Point<int>, List<Mob?>> oldMobMap) {
  Map<Point<int>, List<Mob?>> map = {};
  for (var point in oldMobMap.entries) {
    Map<Point<int>, List<Mob?>> e = {};
    List<Mob?> l = List.from(point.value);
    e = {Point<int>(point.key.x, point.key.y): l};
    map.addAll(e);
  }
  return map;
}

Mob cloneMob(Mob mob, Point<int> position) {
  id++;
  if (mob.runtimeType == ArrowMob) {
    return ArrowMob.clone(mob as ArrowMob, position, id);
  } else if (mob.runtimeType == mob_class.Border) {
    return mob_class.Border.clone(mob as mob_class.Border, position, id);
  } else if (mob.runtimeType == Exit) {
    return Exit.clone(mob as Exit, position, id);
  } else if (mob.runtimeType == Rotator) {
    return Rotator.clone(mob as Rotator, position, id);
  } else if (mob.runtimeType == Switcher) {
    return Switcher.clone(mob as Switcher, position, id);
  } else if (mob.runtimeType == Gate) {
    return Gate.clone(mob as Gate, position, id);
  } else if (mob.runtimeType == TimedDoor) {
    return TimedDoor.clone(mob as TimedDoor, position, id);
  } else if (mob.runtimeType == Player) {
    return Player.clone(mob, position);
  } else if (mob.runtimeType == Info) {
    return Info.clone(mob as Info, position, id);
  } else if (mob.runtimeType == Repeater) {
    return Repeater.clone(mob as Repeater, position, id);
  } else if (mob.runtimeType == Annihilator) {
    return Annihilator.clone(mob as Annihilator, position, id);
  } else if (mob.runtimeType == Wire) {
    return Wire.clone(mob as Wire, position, id);
  } else if (mob.runtimeType == Pressure) {
    return Pressure.clone(mob as Pressure, position, id);
  } else if (mob.runtimeType == Portal) {
    return Portal.clone(mob as Portal, position, id);
  } else {
    throw Exception('Can\'t clone mob $mob');
  }
}

double getCellSize() {
  return 50.0;
}

impressionsFromLiteral(literal) {
  switch (literal) {
    case 'arrowMob':
      return Impressions.arrowMob;
    case 'exit':
      return Impressions.exit;
    case 'border':
      return Impressions.border;
    default:
      throw ('Can\'t decode mob: $literal');
  }
}

Map<Point<int>, List<Mob?>> mobListToMap(List<Mob> moblist) {
  Map<Point<int>, List<Mob?>> mobmap = {};
  for (var i = 0; i < width; i++) {
    for (var j = 0; j < height; j++) {
      mobmap[Point(i, j)] = [];
    }
  }
  for (var mob in moblist) {
    mobmap[mob.position]?.add(mob);
  }

  int maxsize = 16;
  for (var _mobs in mobmap.values) {
    var lnull = List.generate(maxsize - _mobs.length, (index) => null);
    _mobs.addAll(lnull);
  }
  return mobmap;
}

List<Mob> mobMapToList(Map<Point, List<Mob?>> mobmap) {
  List<Mob> moblist = [];
  for (var _moblist in mobmap.values) {
    List<Mob> l = _moblist.whereType<Mob>().where((m) => m is! Player).toList();
    moblist.addAll(l);
  }
  return moblist;
}

void makeChange(Map<Point<int>, List<Mob?>> newMap) {
  changeHistory.add(newMap);
  historyPointer.value = changeHistory.length - 1;
  if (historyPointer.value == 8) {
    List<Map<Point<int>, List<Mob?>>> last8 =
        List.from(changeHistory.getRange(1, changeHistory.length));
    changeHistory = List.from(last8);
    historyPointer.value = 7;
  } else {
    List<Map<Point<int>, List<Mob?>>> newRoot = [
      ...List.from(changeHistory.getRange(0, historyPointer.value)),
      ...[changeHistory.last]
    ];
    changeHistory = List.from(newRoot);
  }
  mobsAsMap = changeHistory.last;
}

const String creeper =
    'eyJ3aWR0aCI6OCwiaGVpZ2h0Ijo4LCJwbGF5ZXJQb3MiOnsieCI6MCwieSI6MH0sIm1vYnMiOlt7ImV4aXQiOnsiaWQiOjEsInBvc2l0aW9uIjp7IngiOjAsInkiOjB9fX0seyJleGl0Ijp7ImlkIjo5LCJwb3NpdGlvbiI6eyJ4IjowLCJ5IjoxfX19LHsiZXhpdCI6eyJpZCI6MTcsInBvc2l0aW9uIjp7IngiOjAsInkiOjJ9fX0seyJleGl0Ijp7ImlkIjoyNSwicG9zaXRpb24iOnsieCI6MCwieSI6M319fSx7ImV4aXQiOnsiaWQiOjMzLCJwb3NpdGlvbiI6eyJ4IjowLCJ5Ijo0fX19LHsiZXhpdCI6eyJpZCI6NDEsInBvc2l0aW9uIjp7IngiOjAsInkiOjV9fX0seyJleGl0Ijp7ImlkIjo0OSwicG9zaXRpb24iOnsieCI6MCwieSI6Nn19fSx7ImV4aXQiOnsiaWQiOjU3LCJwb3NpdGlvbiI6eyJ4IjowLCJ5Ijo3fX19LHsiZXhpdCI6eyJpZCI6MiwicG9zaXRpb24iOnsieCI6MSwieSI6MH19fSx7ImV4aXQiOnsiaWQiOjEwLCJwb3NpdGlvbiI6eyJ4IjoxLCJ5IjoxfX19LHsiYm9yZGVyIjp7ImlkIjoxOCwicG9zaXRpb24iOnsieCI6MSwieSI6Mn19fSx7ImJvcmRlciI6eyJpZCI6MjYsInBvc2l0aW9uIjp7IngiOjEsInkiOjN9fX0seyJleGl0Ijp7ImlkIjozNCwicG9zaXRpb24iOnsieCI6MSwieSI6NH19fSx7ImV4aXQiOnsiaWQiOjQyLCJwb3NpdGlvbiI6eyJ4IjoxLCJ5Ijo1fX19LHsiZXhpdCI6eyJpZCI6NTAsInBvc2l0aW9uIjp7IngiOjEsInkiOjZ9fX0seyJleGl0Ijp7ImlkIjo1OCwicG9zaXRpb24iOnsieCI6MSwieSI6N319fSx7ImV4aXQiOnsiaWQiOjMsInBvc2l0aW9uIjp7IngiOjIsInkiOjB9fX0seyJleGl0Ijp7ImlkIjoxMSwicG9zaXRpb24iOnsieCI6MiwieSI6MX19fSx7ImJvcmRlciI6eyJpZCI6MTksInBvc2l0aW9uIjp7IngiOjIsInkiOjJ9fX0seyJib3JkZXIiOnsiaWQiOjI3LCJwb3NpdGlvbiI6eyJ4IjoyLCJ5IjozfX19LHsiZXhpdCI6eyJpZCI6MzUsInBvc2l0aW9uIjp7IngiOjIsInkiOjR9fX0seyJib3JkZXIiOnsiaWQiOjQzLCJwb3NpdGlvbiI6eyJ4IjoyLCJ5Ijo1fX19LHsiYm9yZGVyIjp7ImlkIjo1MSwicG9zaXRpb24iOnsieCI6MiwieSI6Nn19fSx7ImJvcmRlciI6eyJpZCI6NTksInBvc2l0aW9uIjp7IngiOjIsInkiOjd9fX0seyJleGl0Ijp7ImlkIjo0LCJwb3NpdGlvbiI6eyJ4IjozLCJ5IjowfX19LHsiZXhpdCI6eyJpZCI6MTIsInBvc2l0aW9uIjp7IngiOjMsInkiOjF9fX0seyJleGl0Ijp7ImlkIjoyMCwicG9zaXRpb24iOnsieCI6MywieSI6Mn19fSx7ImV4aXQiOnsiaWQiOjI4LCJwb3NpdGlvbiI6eyJ4IjozLCJ5IjozfX19LHsiYm9yZGVyIjp7ImlkIjozNiwicG9zaXRpb24iOnsieCI6MywieSI6NH19fSx7ImJvcmRlciI6eyJpZCI6NDQsInBvc2l0aW9uIjp7IngiOjMsInkiOjV9fX0seyJib3JkZXIiOnsiaWQiOjUyLCJwb3NpdGlvbiI6eyJ4IjozLCJ5Ijo2fX19LHsiZXhpdCI6eyJpZCI6NjAsInBvc2l0aW9uIjp7IngiOjMsInkiOjd9fX0seyJleGl0Ijp7ImlkIjo1LCJwb3NpdGlvbiI6eyJ4Ijo0LCJ5IjowfX19LHsiZXhpdCI6eyJpZCI6MTMsInBvc2l0aW9uIjp7IngiOjQsInkiOjF9fX0seyJleGl0Ijp7ImlkIjoyMSwicG9zaXRpb24iOnsieCI6NCwieSI6Mn19fSx7ImV4aXQiOnsiaWQiOjI5LCJwb3NpdGlvbiI6eyJ4Ijo0LCJ5IjozfX19LHsiYm9yZGVyIjp7ImlkIjozNywicG9zaXRpb24iOnsieCI6NCwieSI6NH19fSx7ImJvcmRlciI6eyJpZCI6NDUsInBvc2l0aW9uIjp7IngiOjQsInkiOjV9fX0seyJib3JkZXIiOnsiaWQiOjUzLCJwb3NpdGlvbiI6eyJ4Ijo0LCJ5Ijo2fX19LHsiZXhpdCI6eyJpZCI6NjEsInBvc2l0aW9uIjp7IngiOjQsInkiOjd9fX0seyJleGl0Ijp7ImlkIjo2LCJwb3NpdGlvbiI6eyJ4Ijo1LCJ5IjowfX19LHsiZXhpdCI6eyJpZCI6MTQsInBvc2l0aW9uIjp7IngiOjUsInkiOjF9fX0seyJib3JkZXIiOnsiaWQiOjIyLCJwb3NpdGlvbiI6eyJ4Ijo1LCJ5IjoyfX19LHsiYm9yZGVyIjp7ImlkIjozMCwicG9zaXRpb24iOnsieCI6NSwieSI6M319fSx7ImV4aXQiOnsiaWQiOjM4LCJwb3NpdGlvbiI6eyJ4Ijo1LCJ5Ijo0fX19LHsiYm9yZGVyIjp7ImlkIjo0NiwicG9zaXRpb24iOnsieCI6NSwieSI6NX19fSx7ImJvcmRlciI6eyJpZCI6NTQsInBvc2l0aW9uIjp7IngiOjUsInkiOjZ9fX0seyJib3JkZXIiOnsiaWQiOjYyLCJwb3NpdGlvbiI6eyJ4Ijo1LCJ5Ijo3fX19LHsiZXhpdCI6eyJpZCI6NywicG9zaXRpb24iOnsieCI6NiwieSI6MH19fSx7ImV4aXQiOnsiaWQiOjE1LCJwb3NpdGlvbiI6eyJ4Ijo2LCJ5IjoxfX19LHsiYm9yZGVyIjp7ImlkIjoyMywicG9zaXRpb24iOnsieCI6NiwieSI6Mn19fSx7ImJvcmRlciI6eyJpZCI6MzEsInBvc2l0aW9uIjp7IngiOjYsInkiOjN9fX0seyJleGl0Ijp7ImlkIjozOSwicG9zaXRpb24iOnsieCI6NiwieSI6NH19fSx7ImV4aXQiOnsiaWQiOjQ3LCJwb3NpdGlvbiI6eyJ4Ijo2LCJ5Ijo1fX19LHsiZXhpdCI6eyJpZCI6NTUsInBvc2l0aW9uIjp7IngiOjYsInkiOjZ9fX0seyJleGl0Ijp7ImlkIjo2MywicG9zaXRpb24iOnsieCI6NiwieSI6N319fSx7ImV4aXQiOnsiaWQiOjgsInBvc2l0aW9uIjp7IngiOjcsInkiOjB9fX0seyJleGl0Ijp7ImlkIjoxNiwicG9zaXRpb24iOnsieCI6NywieSI6MX19fSx7ImV4aXQiOnsiaWQiOjI0LCJwb3NpdGlvbiI6eyJ4Ijo3LCJ5IjoyfX19LHsiZXhpdCI6eyJpZCI6MzIsInBvc2l0aW9uIjp7IngiOjcsInkiOjN9fX0seyJleGl0Ijp7ImlkIjo0MCwicG9zaXRpb24iOnsieCI6NywieSI6NH19fSx7ImV4aXQiOnsiaWQiOjQ4LCJwb3NpdGlvbiI6eyJ4Ijo3LCJ5Ijo1fX19LHsiZXhpdCI6eyJpZCI6NTYsInBvc2l0aW9uIjp7IngiOjcsInkiOjZ9fX0seyJleGl0Ijp7ImlkIjo2NCwicG9zaXRpb24iOnsieCI6NywieSI6N319fV0sInR1cm5UaW1lIjowLCJ0aXRsZSI6Ik1pbmVjcmFmdCIsImRpYWxvZyI6IiIsInR1cm5zIjowfQ==';
