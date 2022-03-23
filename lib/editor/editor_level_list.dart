import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logicgame/editor/level_editor.dart' hide title;
import 'package:logicgame/level.dart';
import 'package:logicgame/level_list.dart';
import 'package:logicgame/menu/menu.dart';
import 'package:path_provider/path_provider.dart';

late List<Level> createdLevels;

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  if (File('$path/created_levels.json').existsSync()) {
    return File('$path/created_levels.json');
  }
  {
    File('$path/created_levels.json').createSync();
    return File('$path/created_levels.json');
  }
}

Future<File> writeJson(String json) async {
  final file = await _localFile;

  // Write the file
  return file.writeAsString(json);
}

Future<String> readJson() async {
  try {
    final file = await _localFile;

    // Read the file
    final contents = await file.readAsString();

    return contents;
  } catch (e) {
    return '';
  }
}

Future<void> decodeLevels() async {
  List<Level> levels = [];
  String levelsString = await readJson();
  if (levelsString.isNotEmpty) {
    List levelsJson = jsonDecode(levelsString);
    for (var level in levelsJson) {
      levels.add(Level.fromJson(level));
    }
  }
  createdLevels = levels;
}

class EditorLevelList extends StatelessWidget {
  const EditorLevelList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    //ads.showEditorInterstitial();
    //ads.loadEditorIntestitial();
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Menu()));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const Menu()));
              },
              icon: const Icon(Icons.arrow_back_rounded)),
          backgroundColor: Colors.blueGrey[900],
          title: const Text('Создание уровней',
              style: TextStyle(color: Colors.white, fontSize: 20)),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LevelEditor.level(
                              level: Level.empty(
                                  makeProperLevelTitle('Unnamed')))));
                },
                icon: const Icon(Icons.add_rounded)),
            IconButton(
                onPressed: () {
                  fromCodeDialog(context);
                },
                icon: const Icon(Icons.post_add_rounded))
          ],
        ),
        body: LevelList(
          levels: createdLevels,
          isCampaign: false,
        ),
      ),
    );
  }

  void fromCodeDialog(BuildContext context) async {
    ClipboardData? code;
    Level level;
    await Clipboard.getData('text/plain').then((value) {
      code = value;
      try {
        var decoded = utf8.decode(base64.decode(code!.text!));
        var json = jsonDecode(decoded);
        level = Level.fromJson(json);
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.blueGrey[900],
                title: const Text(
                  'Создать уровень из буфера обмена',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                content: null,
                actions: [
                  Center(
                    child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LevelEditor.level(
                                        level: level,
                                      )));
                        },
                        icon: const Icon(Icons.post_add_rounded),
                        label: const Text(
                          'Создать',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        )),
                  )
                ],
              );
            });
      } catch (e) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.blueGrey[900],
                title: const Text(
                  'Не удалось создать уровень',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                content: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            });
      }
    });
  }
}

String makeProperLevelTitle(String fromTitle) {
  var existingTitles =
      List.generate(createdLevels.length, (i) => createdLevels[i].title);
  if (existingTitles.contains(fromTitle)) {
    int amount =
        existingTitles.where((title) => title.startsWith(fromTitle)).length;
    return '$fromTitle-$amount';
  }
  return fromTitle;
}
