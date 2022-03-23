import 'package:flutter/material.dart';
import 'package:logicgame/menu/menu.dart';
import 'package:logicgame/storage/storage.dart';
import 'endless_game.dart' as endless;
import 'package:logicgame/generator/generator.dart' as generator;
import 'package:logicgame/global_stats.dart' as stats;
import 'endless_stats.dart' as estats;
import 'package:easy_localization/easy_localization.dart';

//did the player decline log into play services
//bool isLoginDeclined = false;

late ValueNotifier<bool> isPlainAvailable;
late ValueNotifier<bool> isPlainChosen;

late ValueNotifier<bool> isXWallAvailable;
late ValueNotifier<bool> isXWallChosen;

late ValueNotifier<bool> isYWallAvailable;
late ValueNotifier<bool> isYWallChosen;

late ValueNotifier<bool> isPlainHardAvailable;
late ValueNotifier<bool> isPlainHardChosen;

late ValueNotifier<bool> isYCrossAvailable;
late ValueNotifier<bool> isYCrossChosen;

late ValueNotifier<bool> isLaserRoomAvailable;
late ValueNotifier<bool> isLaserRoomChosen;

late ValueNotifier<bool> isPortalsAvailable;
late ValueNotifier<bool> isPortalsChosen;

ValueNotifier<int> shards = ValueNotifier(0);

class EndlessMenu extends StatelessWidget {
  final int maxRow;
  final int highScore;
  final int levelsPassed;

  const EndlessMenu(
      {Key? key,
      required this.maxRow,
      required this.highScore,
      required this.levelsPassed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[900],
          title:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('endless_mode'.tr(),
                style: TextStyle(color: Colors.white, fontSize: 20)),
            CoinDisplay()
          ]),
          leading: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (globalContext) => const Menu()));
              },
              icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: Container(
            color: Colors.blueGrey[900],
            child: Column(children: [
              AnimatedScoreText(
                maxRow: maxRow,
                highScore: highScore,
                levelsPassed: levelsPassed,
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LevelTypeChooser(),
                ),
              ),
              const Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: EndlessMenuButtons()),
            ])),
      ),
      onWillPop: () async {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (globalContext) => const Menu()));
        return true;
      },
    );
  }
}

class CoinDisplay extends StatefulWidget {
  const CoinDisplay({Key? key}) : super(key: key);

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  @override
  void initState() {
    super.initState();

    shards.value = stats.coins;

    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    animation = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(controller)
      ..addListener(() {
        setState(() {});
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: Row(children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: [Colors.purple[400]!, Colors.purple[600]!])
                  .createShader(bounds),
          child: const Icon(
            Icons.play_arrow_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        Opacity(
          opacity: animation.value,
          child: ValueListenableBuilder(
            valueListenable: shards,
            builder: (context, s, child) => Text('$s',
                style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),
        )
      ]),
    );
  }
}

class AnimatedScoreText extends StatefulWidget {
  final int maxRow;
  final int highScore;
  final int levelsPassed;
  const AnimatedScoreText({
    Key? key,
    required this.maxRow,
    required this.highScore,
    required this.levelsPassed,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnimatedScoreTextState();
}

class _AnimatedScoreTextState extends State<AnimatedScoreText>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    animation = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(controller)
      ..addListener(() {
        setState(() {});
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (stats.charSkinsOwn[26] == 'false' && widget.highScore > 9000) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        showDialog(
            context: context,
            builder: (BuildContext context) => const SkinDialog(
                26,
                'IT’S OVER NINE THOUSAAAAAND!',
                'В хранилище доступна награда!'));
        stats.charSkinsOwn[26] = 'true';
        stats.writeStats();
      });
    }
    return Center(
      child: Opacity(
        opacity: animation.value,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Лучший счёт: ',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Text(
                        '${(animation.value * (widget.highScore)).toInt()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Уровней подряд: ',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      Text('${(animation.value * (widget.maxRow)).toInt()}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Пройдено уровней: ',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      Text(
                          '${(animation.value * (widget.levelsPassed)).toInt()}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EndlessMenuButtons extends StatelessWidget {
  const EndlessMenuButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //let the player choose if they want to log in play games
    // if (!isLoginDeclined) {
    //   WidgetsBinding.instance?.addPostFrameCallback((_) {
    //     showDialog(
    //         barrierDismissible: false,
    //         context: context,
    //         builder: (context) {
    //           return AlertDialog(
    //             backgroundColor: Colors.blueGrey[900],
    //             title: Text(
    //               'play_services_alert_title'.tr(),
    //               style: const TextStyle(color: Colors.white, fontSize: 20),
    //             ),
    //             content: Text(
    //               'play_services_alert_content'.tr(),
    //               style: const TextStyle(color: Colors.white, fontSize: 16),
    //             ),
    //             actions: [
    //               MaterialButton(
    //                 onPressed: () {
    //                   isLoginDeclined = true;
    //                   Navigator.pop(context);
    //                 },
    //                 child: Text(
    //                   'play_services_decline'.tr(),
    //                   style: const TextStyle(color: Colors.white, fontSize: 16),
    //                 ),
    //               ),
    //               MaterialButton(
    //                 onPressed: () {
    //                   GamesServices.signIn()
    //                       .then((value) => Navigator.pop(context));
    //                 },
    //                 child: Text(
    //                   'play_services_login'.tr(),
    //                   style: const TextStyle(color: Colors.white, fontSize: 16),
    //                 ),
    //               ),
    //             ],
    //           );
    //         });
    //   });
    // }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        //Used to access Play Games
        // ElevatedButton.icon(
        //     onPressed: () => {
        //           GamesServices.isSignedIn.then((signed) => {
        //                 if (signed)
        //                   {GamesServices.showLeaderboards()}
        //                 else
        //                   {
        //                     GamesServices.signIn()
        //                         .then((_) => GamesServices.showLeaderboards())
        //                   }
        //               })
        //         },
        //     icon: const Icon(Icons.leaderboard_rounded),
        //     label: const Text('Лидеры',
        //         style: TextStyle(color: Colors.white, fontSize: 20))),
        ElevatedButton.icon(
            onPressed: () => play(context),
            icon: const Icon(Icons.casino_rounded),
            label: const Text('Играть',
                style: TextStyle(color: Colors.white, fontSize: 20))),
      ],
    );
  }

  void play(BuildContext context) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (globalContext) => endless.EndlessGame(
                  level: generator.generateLevel(),
                  levelScore: generator.levelScore,
                )));
  }
}

class LevelTypeChooser extends StatefulWidget {
  const LevelTypeChooser({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LevelTypeChooserState();
}

class _LevelTypeChooserState extends State<LevelTypeChooser> {
  @override
  void initState() {
    isPlainAvailable = ValueNotifier(estats.isPlainAvailable);
    isPlainChosen = ValueNotifier(estats.isPlainChosen);

    isXWallAvailable = ValueNotifier(estats.isXWallAvailable);
    isXWallChosen = ValueNotifier(estats.isXWallChosen);

    isYWallAvailable = ValueNotifier(estats.isYWallAvailable);
    isYWallChosen = ValueNotifier(estats.isYWallChosen);

    isPlainHardAvailable = ValueNotifier(estats.isPlainHardAvailable);
    isPlainHardChosen = ValueNotifier(estats.isPlainHardChosen);

    isYCrossAvailable = ValueNotifier(estats.isYCrossAvailable);
    isYCrossChosen = ValueNotifier(estats.isYCrossChosen);

    isLaserRoomAvailable = ValueNotifier(estats.isLaserRoomAvailable);
    isLaserRoomChosen = ValueNotifier(estats.isLaserRoomChosen);

    isPortalsAvailable = ValueNotifier(estats.isPortalsAvailable);
    isPortalsChosen = ValueNotifier(estats.isPortalsChosen);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'level_type_choose'.tr(),
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: ListView(children: [
                LevelTypeTab(
                  initialState: isPlainChosen.value,
                  initialAvailability: isPlainAvailable.value,
                  title: 'pattern_simple',
                  description: 'pattern_simple_desc',
                  chooseNotifier: isPlainChosen,
                  availabilityNotifier: isPlainAvailable,
                  cost: 0,
                  isPurchaseable: false,
                ),
                const Divider(
                  height: 2,
                ),
                LevelTypeTab(
                  initialState: isXWallChosen.value,
                  initialAvailability: isXWallAvailable.value,
                  title: 'pattern_xwall',
                  description: 'pattern_xwall_desc',
                  chooseNotifier: isXWallChosen,
                  availabilityNotifier: isXWallAvailable,
                  cost: 25,
                ),
                const Divider(
                  height: 2,
                ),
                LevelTypeTab(
                  initialState: isYWallChosen.value,
                  initialAvailability: isYWallAvailable.value,
                  title: 'pattern_ywall',
                  description: 'pattern_ywall_desc',
                  chooseNotifier: isYWallChosen,
                  availabilityNotifier: isYWallAvailable,
                  cost: 50,
                ),
                const Divider(
                  height: 2,
                ),
                LevelTypeTab(
                  initialState: isPlainHardChosen.value,
                  initialAvailability: isPlainHardAvailable.value,
                  title: 'pattern_plainhard',
                  description: 'pattern_plainhard_desc',
                  chooseNotifier: isPlainHardChosen,
                  availabilityNotifier: isPlainHardAvailable,
                  cost: 100,
                ),
                const Divider(
                  height: 2,
                ),
                LevelTypeTab(
                  initialState: isYCrossChosen.value,
                  initialAvailability: isYCrossAvailable.value,
                  title: 'pattern_ycross',
                  description: 'pattern_ycross_desc',
                  chooseNotifier: isYCrossChosen,
                  availabilityNotifier: isYCrossAvailable,
                  cost: 100,
                ),
                const Divider(
                  height: 2,
                ),
                LevelTypeTab(
                  initialState: isLaserRoomChosen.value,
                  initialAvailability: isLaserRoomAvailable.value,
                  title: 'pattern_laserroom',
                  description: 'pattern_laserroom_desc',
                  chooseNotifier: isLaserRoomChosen,
                  availabilityNotifier: isLaserRoomAvailable,
                  cost: 100,
                ),
                const Divider(
                  height: 2,
                ),
                LevelTypeTab(
                  initialState: isPortalsChosen.value,
                  initialAvailability: isPortalsAvailable.value,
                  title: 'pattern_portals',
                  description: 'pattern_portals_desc',
                  chooseNotifier: isPortalsChosen,
                  availabilityNotifier: isPortalsAvailable,
                  cost: 100,
                ),
              ]),
            ),
          ),
        )
      ],
    );
  }
}

class LevelTypeTab extends StatefulWidget {
  final bool initialState;
  final String title;
  final String description;
  final ValueNotifier<bool> availabilityNotifier;
  final ValueNotifier<bool> chooseNotifier;
  final bool initialAvailability;
  final int cost;
  final bool isPurchaseable;

  const LevelTypeTab(
      {Key? key,
      required this.initialState,
      required this.initialAvailability,
      required this.title,
      required this.description,
      required this.chooseNotifier,
      required this.availabilityNotifier,
      required this.cost,
      this.isPurchaseable = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LevelTypeTabState();
}

class _LevelTypeTabState extends State<LevelTypeTab> {
  late bool isOn;
  late bool isAvailable;

  @override
  void initState() {
    isOn = widget.initialState;
    isAvailable = widget.initialAvailability;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isAvailable) {
          showDialog(
              context: context,
              builder: (context) => PatternDialog(
                  widget.title.tr(),
                  widget.description.tr(),
                  widget.availabilityNotifier,
                  widget.cost)).then((_) {
            if (widget.availabilityNotifier.value) {
              setState(() {
                isAvailable = true;
              });
            }
          });
        }
      },
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF263238), Color(0xFF37474F)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title.tr(),
                  style: TextStyle(
                    color: isAvailable ? Colors.white : Colors.white24,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            isAvailable && widget.isPurchaseable
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Checkbox(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(2))),
                        value: isOn,
                        onChanged: (v) {
                          setState(() {
                            isOn = v ?? isOn;
                          });
                          widget.chooseNotifier.value =
                              v ?? widget.chooseNotifier.value;
                          _applyPatternPreferences();
                        }),
                  )
                : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}

void _applyPatternPreferences() {
  estats.isPlainAvailable = isPlainAvailable.value;
  estats.isPlainChosen = isPlainAvailable.value;

  estats.isXWallAvailable = isXWallAvailable.value;
  estats.isXWallChosen = isXWallChosen.value;

  estats.isYWallAvailable = isYWallAvailable.value;
  estats.isYWallChosen = isYWallChosen.value;

  estats.isPlainHardAvailable = isPlainHardAvailable.value;
  estats.isPlainHardChosen = isPlainHardChosen.value;

  estats.isYCrossAvailable = isYCrossAvailable.value;
  estats.isYCrossChosen = isYCrossChosen.value;

  estats.isLaserRoomAvailable = isLaserRoomAvailable.value;
  estats.isLaserRoomChosen = isLaserRoomChosen.value;

  estats.isPortalsAvailable = isPortalsAvailable.value;
  estats.isPortalsChosen = isPortalsChosen.value;

  estats.writeStats();
}

class PatternDialog extends StatelessWidget {
  final int cost;
  final String title;
  final String description;
  final ValueNotifier availabilityNotifier;

  const PatternDialog(
      this.title, this.description, this.availabilityNotifier, this.cost,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blueGrey[900],
        content: Text(
          description,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                  onPressed: () {
                    if (shards.value > cost) {
                      availabilityNotifier.value = true;
                      shards.value -= cost;
                      stats.coins = shards.value;
                      stats.writeStats();
                      _applyPatternPreferences();
                      Navigator.pop(context);
                    }
                  },
                  icon: const ShardIcon(),
                  label: Text(
                    '$cost',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  )),
            ],
          ),
        ]);
  }
}
