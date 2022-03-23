import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logicgame/campaign_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:logicgame/editor/editor_level_list.dart';
import 'package:logicgame/game/impressions.dart';
import 'package:logicgame/generator/endless_menu.dart';
import 'package:logicgame/generator/endless_stats.dart' as endless;
import 'package:logicgame/generator/generator.dart' as generator;
import 'menu_game.dart' as menu_game;

import 'package:logicgame/settings.dart' as settings;
import 'package:logicgame/global_stats.dart' as stats;
import 'package:logicgame/storage/storage.dart' hide charSkinsOwn;

import 'package:url_launcher/url_launcher.dart';

const tiktokLink = 'https://www.tiktok.com/@peaashmeter';
const discordLink = 'https://discord.gg/qU2G8hFpt9';

ValueNotifier<bool> interfaceNotifier = ValueNotifier(false);
ValueNotifier<bool> backgroundNotifier = ValueNotifier(true);

class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late Widget game;

  @override
  void initState() {
    backgroundNotifier.value = settings.isBackground;

    game = menu_game.MenuGame(
        level: generator.generateLevel(isTimed: true, time: 1000));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            FloatingActionButton(
              heroTag: 'hero1',
              onPressed: () {
                _launchURL(discordLink);
              },
              child: Image.asset(
                'assets/misc/discord.png',
                width: 32,
              ),
            ),
            FloatingActionButton(
                heroTag: 'hero2',
                onPressed: () {
                  _launchURL(tiktokLink);
                },
                child: Image.asset(
                  'assets/misc/tiktok.png',
                  width: 32,
                )),
          ],
        ),
        body: SizedBox.expand(
          child: Stack(children: [
            ValueListenableBuilder(
                valueListenable: backgroundNotifier,
                builder: (context, bool value, child) {
                  if (value) {
                    return Transform.scale(
                      scale: 2.0,
                      child: game,
                    );
                  } else {
                    return Container(
                      color: Colors.blueGrey[900],
                    );
                  }
                }),
            Opacity(
              opacity: 0.90,
              child: Container(
                color: Colors.blueGrey[900],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: Container()),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          RotatingSkin(Random().nextInt(stats.charSkinsInGame)),
                          Image.asset('assets/logo/logo2.png'),
                          RotatingSkin(Random().nextInt(stats.charSkinsInGame))
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Container()),
                    MenuTab(
                      title: 'camp_title'.tr(),
                      route: const CampaignList(),
                      icon: Icons.play_arrow_rounded,
                    ),
                    MenuTab(
                      title: 'rng'.tr(),
                      route: Builder(builder: (BuildContext context) {
                        return EndlessMenu(
                            maxRow: endless.maxRow,
                            highScore: endless.highScore,
                            levelsPassed: endless.levelsPassed);
                      }),
                      icon: Icons.casino_rounded,
                    ),
                    MenuTab(
                        title: 'vault'.tr(),
                        route: const Storage(),
                        icon: Icons.inventory_2_rounded),
                    EditorTab(
                      title: 'editor'.tr(),
                      route: const EditorLevelList(),
                      icon: Icons.square_foot_rounded,
                    ),
                    RedeemCodeTab(
                      title: 'redeem_code'.tr(),
                      icon: Icons.edit_rounded,
                      formKey: GlobalKey<FormState>(),
                    ),
                    DialogTab(
                        title: 'settings'.tr(),
                        route: const SettingsDialog(),
                        icon: Icons.settings_rounded),
                    DialogTab(
                        title: 'about_title'.tr(),
                        route: const AboutDialog(),
                        icon: Icons.info_outline_rounded),
                    Expanded(flex: 5, child: Container()),
                  ],
                ),
              ),
            ),
          ]),
        ),
        // bottomNavigationBar: ValueListenableBuilder(
        //   valueListenable: isBannerLoaded,
        //   builder: (context, bool loaded, child) {
        //     if (loaded) {
        //       return Container(
        //           color: Colors.blueGrey[900],
        //           width: banner.size.width.toDouble(),
        //           height: banner.size.height.toDouble(),
        //           child: AdWidget(ad: banner));
        //     } else {
        //       return Container();
        //     }
        //   },
        // ),
      ),
    );
  }
}

void _launchURL(String url) async {
  if (!await launch(url)) throw 'Could not launch $url';
}

class RotatingSkin extends StatefulWidget {
  final int id;
  const RotatingSkin(this.id, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RotatingSkinState();
}

class _RotatingSkinState extends State<RotatingSkin>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        duration: const Duration(milliseconds: 5000), vsync: this);

    animation = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.linear))
        .animate(controller)
      ..addListener(() {
        setState(() {});
      });

    controller.repeat();
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var fw = sin(animation.value * 2 * pi) * 8;

    return GestureDetector(
      onTap: () {
        print('skinid: ${widget.id}');
        if (widget.id == 3 && stats.charSkinsOwn[3] == 'false') {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.blueGrey[900],
                  title: const Text(
                    'Обнаружен секрет!',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  content: const Text(
                    '...?',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              });
          stats.charSkinsOwn[3] = 'true';
          stats.writeStats();
        }
      },
      child: SizedBox(
          width: 56 + fw,
          height: 56 + fw,
          child: getPlayerImpression(widget.id, preview: true)),
    );
  }
}

class MenuTab extends StatelessWidget {
  final String title;
  final Widget? route;
  final IconData icon;
  const MenuTab(
      {Key? key, required this.title, required this.route, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: backgroundNotifier,
        builder: (context, bool simple, child) {
          return Material(
            color: Colors.blueGrey[900],
            child: InkWell(
              onTap: () {
                _onTap(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Expanded(child: SizedBox.shrink()),
                    Expanded(
                      flex: 5,
                      child: Text(title,
                          textAlign: TextAlign.start,
                          style: !simple
                              ? const TextStyle(
                                  shadows: [],
                                  color: Colors.white,
                                  fontSize: 20)
                              : const TextStyle(shadows: [
                                  Shadow(
                                    offset: Offset(3, 3),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ], color: Colors.white, fontSize: 20)),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                    Expanded(
                      child: Stack(children: [
                        simple
                            ? Positioned(
                                left: 3.0,
                                top: 3.0,
                                child: Icon(
                                  icon,
                                  size: 32,
                                  color: Colors.black54,
                                ),
                              )
                            : const SizedBox.shrink(),
                        Icon(
                          icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ]),
                    ),
                    const Expanded(child: SizedBox.shrink())
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _onTap(BuildContext context) {
    if (route != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => route!));
    }
  }
}

class DialogTab extends MenuTab {
  const DialogTab(
      {Key? key,
      required String title,
      required Widget? route,
      required IconData icon})
      : super(key: key, title: title, route: route, icon: icon);

  @override
  void _onTap(BuildContext context) {
    if (route != null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return route!;
          }).then((value) => settings.writeSettings());
    }
  }
}

class EditorTab extends MenuTab {
  const EditorTab(
      {Key? key,
      required String title,
      required Widget route,
      required IconData icon})
      : super(key: key, title: title, route: route, icon: icon);

  @override
  void _onTap(BuildContext context) {
    decodeLevels().then((value) => Navigator.push(context,
        MaterialPageRoute(builder: (context) => const EditorLevelList())));
  }
}

class AboutDialog extends StatelessWidget {
  const AboutDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        title: Text(
          'about_title'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: TextField(
          controller: TextEditingController(text: 'about_text'.tr()),
          maxLines: 10,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ));
  }
}

class RedeemCodeTab extends MenuTab {
  final GlobalKey<FormState> formKey;
  const RedeemCodeTab(
      {Key? key,
      required String title,
      required IconData icon,
      required this.formKey})
      : super(key: key, title: title, route: const Placeholder(), icon: icon);

  @override
  void _onTap(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return RedeemCodeDialog(
            formKey: formKey,
          );
        });
  }
}

class RedeemCodeDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const RedeemCodeDialog({
    Key? key,
    required this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(
          'redeem_code'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    labelText: 'Код',
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                onSaved: (value) => _checkCode(value, context),
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                }
              },
              child: const Text('Применить'),
            ),
          )
        ]);
  }
}

void _checkCode(String? code, BuildContext context) {
  Navigator.pop(context);
  switch (code?.toLowerCase().replaceAll(' ', '')) {
    case 'антананариву':
      if (stats.charSkinsOwn[10] == 'false') {
        showDialog(
            context: context,
            builder: (BuildContext context) => const SkinDialog(
                10, 'Обнаружен секрет', 'Добро пожаловать в Мадагаскар!'));
        stats.charSkinsOwn[10] = 'true';
        stats.writeStats();
      }

      break;
    case 'antananarivo':
      if (stats.charSkinsOwn[10] == 'false') {
        showDialog(
            context: context,
            builder: (BuildContext context) => const SkinDialog(
                10, 'Обнаружен секрет', 'Добро пожаловать в Мадагаскар!'));
        stats.charSkinsOwn[10] = 'true';
        stats.writeStats();
      }
      break;
    case 'создатель':
      showDialog(
          context: context,
          builder: (BuildContext context) => const SkinDialog(
              17,
              'Мастер диалогов',
              'Создатель этого мира – PeaAshMeter. Это имя лучше не называть...'));

      break;
    case 'creator':
      showDialog(
          context: context,
          builder: (BuildContext context) => const SkinDialog(
              17,
              'Мастер диалогов',
              'Создатель этого мира – PeaAshMeter. Это имя лучше не называть...'));

      break;
    case 'peaashmeter':
      showDialog(
          context: context,
          builder: (BuildContext context) =>
              const SkinDialog(17, 'Мастер диалогов', 'Ты совершаешь ошибку!'));

      break;
    case 'amperehaste':
      showDialog(
          context: context,
          builder: (BuildContext context) =>
              const SkinDialog(17, 'Обнаружен секрет!', 'Имена и анаграммы.'));
      stats.charSkinsOwn[17] = 'true';
      stats.writeStats();
      break;
    case 'cocacola':
      showDialog(
          context: context,
          builder: (BuildContext context) => const SkinDialog(
              18, 'Обнаружен секрет!', 'Праздника вкус всегда настоящий!'));
      stats.charSkinsOwn[18] = 'true';
      stats.writeStats();
      break;
    case 'ettubrute':
      if (stats.charSkinsOwn[24] == 'false') {
        showDialog(
            context: context,
            builder: (BuildContext context) =>
                const SkinDialog(24, 'Обнаружен секрет!', 'И ты, Брут?'));
        stats.charSkinsOwn[24] = 'true';
        stats.writeStats();
      }

      break;
    case 'goldenwatermelon':
      if (stats.charSkinsOwn[28] == 'false') {
        showDialog(
            context: context,
            builder: (BuildContext context) => const SkinDialog(
                28, 'Обнаружен секрет', 'Нет, это точно не дыня.'));
        stats.charSkinsOwn[28] = 'true';
        stats.writeStats();
      }
      break;
    case 'xjhnlnfq':
      if (stats.charSkinsOwn[29] == 'false') {
        showDialog(
            context: context,
            builder: (BuildContext context) =>
                const SkinDialog(29, 'Обнаружен секрет', 'Неправильный путь.'));
        stats.charSkinsOwn[29] = 'true';
        stats.writeStats();
      }
      break;
    //secret code to disable ads
    case 'd6bad3451dbd9a51':
      stats.removeAds = true;
      stats.writeStats();
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            backgroundColor: Colors.blueGrey[900],
            title: Text(
              'dmaster'.tr(),
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            content: Text(
              'ads_removed'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.white),
            )),
      );
      break;
    default:
  }
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: Colors.blueGrey[900],
      title: Text(
        'settings'.tr(),
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: ControlsSwitch(),
        ),
        // Padding(
        //   padding: EdgeInsets.all(8.0),
        //   child: InterfaceSwitch(),
        // ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: AnimationsSwitch(),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: BackgroundSwitch(),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: SoundSwitch(),
        ),
      ],
    );
  }
}

class ControlsSwitch extends StatefulWidget {
  const ControlsSwitch({Key? key}) : super(key: key);

  @override
  State<ControlsSwitch> createState() => _ControlsSwitchState();
}

class _ControlsSwitchState extends State<ControlsSwitch> {
  bool _isDpad = settings.isDpad;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: _isDpad
            ? Text(
                'settings_controls_1'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : Text('settings_controls_0'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20)),
        value: _isDpad,
        onChanged: (bool value) {
          setState(() {
            _isDpad = value;
          });
          settings.isDpad = _isDpad;
        });
  }
}

class InterfaceSwitch extends StatefulWidget {
  const InterfaceSwitch({Key? key}) : super(key: key);

  @override
  State<InterfaceSwitch> createState() => _InterfaceSwitchState();
}

class _InterfaceSwitchState extends State<InterfaceSwitch> {
  bool _isSimpleInterface = settings.isSimpleInterface;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: _isSimpleInterface
            ? Text(
                'settings_interface_1'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : Text('settings_interface_0'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20)),
        value: _isSimpleInterface,
        onChanged: (bool value) {
          setState(() {
            _isSimpleInterface = value;
          });
          settings.isSimpleInterface = _isSimpleInterface;
          interfaceNotifier.value = _isSimpleInterface;
        });
  }
}

class AnimationsSwitch extends StatefulWidget {
  const AnimationsSwitch({Key? key}) : super(key: key);

  @override
  State<AnimationsSwitch> createState() => _AnimationsSwitchState();
}

class _AnimationsSwitchState extends State<AnimationsSwitch> {
  bool _isMoreAnimations = settings.isMoreAnimations;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: _isMoreAnimations
            ? Text(
                'settings_animations_1'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : Text('settings_animations_0'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20)),
        value: _isMoreAnimations,
        onChanged: (bool value) {
          setState(() {
            _isMoreAnimations = value;
          });
          settings.isMoreAnimations = _isMoreAnimations;
        });
  }
}

class BackgroundSwitch extends StatefulWidget {
  const BackgroundSwitch({Key? key}) : super(key: key);

  @override
  State<BackgroundSwitch> createState() => _BackgroundSwitchState();
}

class _BackgroundSwitchState extends State<BackgroundSwitch> {
  bool _isBackground = settings.isBackground;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: _isBackground
            ? const Text(
                'Задний фон',
                style: TextStyle(color: Colors.white, fontSize: 20),
              )
            : const Text('Простое меню',
                style: TextStyle(color: Colors.white, fontSize: 20)),
        value: _isBackground,
        onChanged: (bool value) {
          setState(() {
            _isBackground = value;
          });
          settings.isBackground = _isBackground;
          backgroundNotifier.value = _isBackground;
        });
  }
}

class SoundSwitch extends StatefulWidget {
  const SoundSwitch({Key? key}) : super(key: key);

  @override
  State<SoundSwitch> createState() => _ControlsSoundState();
}

class _ControlsSoundState extends State<SoundSwitch> {
  bool _isSound = settings.isSound;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        title: _isSound
            ? Text(
                'settings_sound_1'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : Text('settings_sound_0'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20)),
        value: _isSound,
        onChanged: (bool value) {
          setState(() {
            _isSound = value;
          });
          settings.isSound = _isSound;
        });
  }
}
