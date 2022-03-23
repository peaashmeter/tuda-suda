import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logicgame/game/directions.dart';
import 'package:logicgame/game/impressions.dart';
import 'package:logicgame/menu/menu.dart';
import 'package:logicgame/global_stats.dart' as stats;

ValueNotifier<int> skinTabNotifier = ValueNotifier(0);
ValueNotifier<int> charId = ValueNotifier(0);
ValueNotifier<int> arrowMobId = ValueNotifier(0);
ValueNotifier<int> borderId = ValueNotifier(0);
ValueNotifier<List<String>> charSkinsOwn = ValueNotifier<List<String>>([]);
ValueNotifier<List<String>> arrowMobSkinsOwn = ValueNotifier<List<String>>([]);
ValueNotifier<List<String>> borderSkinsOwn = ValueNotifier<List<String>>([]);
ValueNotifier<int> shards = ValueNotifier(0);

late double skinSize;

class Storage extends StatelessWidget {
  const Storage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    charId.value = stats.charSkinId;
    charSkinsOwn.value = stats.charSkinsOwn;
    arrowMobSkinsOwn.value = stats.arrowMobSkinsOwn;
    arrowMobId.value = stats.arrowMobSkinId;
    borderId.value = stats.borderSkinId;
    borderSkinsOwn.value = stats.borderSkinsOwn;

    shards.value = stats.coins;

    skinTabNotifier.value = 0;

    skinSize = MediaQuery.of(context).size.width / 6;

    return WillPopScope(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blueGrey[900],
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Хранилище',
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
            // actions: [
            //   IconButton(
            //       onPressed: () {
            //         addShards(context);
            //       },
            //       icon: const Icon(
            //         Icons.add_rounded,
            //         size: 32,
            //       ))
            // ],
          ),
          body: Column(
            children: [
              Expanded(
                  flex: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: Colors.blueGrey[900],
                      ),
                      Column(
                        children: [
                          Expanded(child: Container()),
                          const Material(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              elevation: 5,
                              child: CharPreview()),
                          ValueListenableBuilder(
                              valueListenable: skinTabNotifier,
                              builder: (context, int id, widget) {
                                return ValueListenableBuilder(
                                    valueListenable: _getTabNotifier(id),
                                    builder: (context, int tabId, widget) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _getSkinDialogMap(id)[tabId]?.title ??
                                              'Красный',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20),
                                        ),
                                      );
                                    });
                              }),
                          Expanded(child: Container()),
                        ],
                      )
                    ],
                  )),
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.blueGrey[900],
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          unselectedLabelColor: Colors.blueGrey[900],
                          onTap: (value) => skinTabNotifier.value = value,
                          tabs: [
                            Tab(
                                child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: getPlayerImpression(0))),
                            Tab(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: getArrowMobImpression(
                                    0, Directions.right, skinSize),
                              ),
                            ),
                            Tab(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: getBorderImpression(0, 0, 32),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(children: [
                            Container(
                              color: Colors.blueGrey[900],
                              child: const SkinGridView(0),
                            ),
                            Container(
                              color: Colors.blueGrey[900],
                              child: const SkinGridView(1),
                            ),
                            Container(
                              color: Colors.blueGrey[900],
                              child: const SkinGridView(2),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
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
        ValueListenableBuilder(
            valueListenable: shards,
            builder: (BuildContext context, int _shards, widget) {
              return Opacity(
                opacity: animation.value,
                child: Text('${stats.coins}',
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
              );
            })
      ]),
    );
  }
}

class CharPreview extends StatelessWidget {
  const CharPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: skinTabNotifier,
        builder: (context, int type, widget) {
          return ValueListenableBuilder(
              valueListenable: _getTabNotifier(type),
              builder: (context, int id, widget) {
                return SizedBox(
                    width: 100, height: 100, child: _getSkin(type, id));
              });
        });
  }
}

class SkinGridView extends StatelessWidget {
  final int type;
  const SkinGridView(this.type, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ValueListenableBuilder(
            valueListenable: _getValueNotifier(),
            builder: (context, int id, widget) {
              return ValueListenableBuilder(
                  valueListenable: charSkinsOwn,
                  builder: (context, List<String> skinsOwn, widget) {
                    return GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        children: [
                          ..._genSkinsList(id),
                        ]);
                  });
            }),
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blueGrey[900]!, Colors.blueGrey])),
          height: stats.charSkinsOwn[4] == 'false' ? 10000 : 0,
          child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                  onTap: () => unlockSpiderSkin(context),
                  child: Image.asset('assets/misc/hole.png'))),
        )
      ],
    );
  }

  void unlockSpiderSkin(BuildContext context) {
    if (charSkinsOwn.value[4] == 'false') {
      showDialog(
          context: context,
          builder: (BuildContext context) =>
              const SkinDialog(4, 'Обнаружен секрет', 'Дно было пробито'));
      charSkinsOwn.value[4] = 'true';
    }
  }

  ValueNotifier<int> _getValueNotifier() {
    switch (type) {
      case 0:
        return charId;
      case 1:
        return arrowMobId;
      case 2:
        return borderId;
      default:
        return charId;
    }
  }

  List<Widget> _genSkinsList(int selected) {
    switch (type) {
      case 0:
        int length = stats.charSkinsInGame;
        List<SkinSelector> skins = [];
        for (var i = 0; i < length; i++) {
          bool sel = false;
          bool own = false;
          if (i == selected) {
            sel = true;
          }
          if (stats.charSkinsOwn[i] == 'true') {
            own = true;
          }

          skins.add(SkinSelector(
            i,
            !own,
            type,
            selected: sel,
            key: UniqueKey(),
          ));
        }
        return skins;
      case 1:
        int length = stats.arrowMobSkinsInGame;
        List<SkinSelector> skins = [];
        for (var i = 0; i < length; i++) {
          bool sel = false;
          bool own = false;
          if (i == selected) {
            sel = true;
          }
          if (stats.arrowMobSkinsOwn[i] == 'true') {
            own = true;
          }

          skins.add(SkinSelector(
            i,
            !own,
            type,
            selected: sel,
            key: UniqueKey(),
          ));
        }

        return skins;
      case 2:
        int length = stats.borderSkinsInGame;
        List<Widget> skins = [];
        for (var i = 0; i < length; i++) {
          bool sel = false;
          bool own = false;
          if (i == selected) {
            sel = true;
          }
          if (stats.borderSkinsOwn[i] == 'true') {
            own = true;
          }

          skins.add(ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SkinSelector(
              i,
              !own,
              type,
              selected: sel,
              key: UniqueKey(),
            ),
          ));
        }
        return skins;
      default:
        throw Exception('Wrong type of skin: $type');
    }
  }
}

Map<int, SkinDialog> charSkinDialogs = {
  0: SkinDialog(
    0,
    'skin0_name'.tr(),
    'skin0_desc'.tr(),
    isPurchasable: false,
  ),
  1: const SkinDialog(
    1,
    'Янтарный',
    'Как обычный, но другого цвета.',
    isPurchasable: true,
    cost: 20,
  ),
  2: const SkinDialog(
    2,
    'Жёлтый',
    'Как обычный, но другого цвета.',
    isPurchasable: true,
    cost: 20,
  ),
  3: const SkinDialog(
    3,
    'Арбуз',
    'Квадратные арбузы удобны в транспортировке: их можно ставить друг на друга.',
    isPurchasable: false,
  ),
  4: const SkinDialog(
    4,
    'Ужас из глубин',
    'Чтобы открыть, необходимо пробить дно.',
    isPurchasable: false,
  ),
  5: const SkinDialog(
    5,
    'Черепаховый',
    'На ее панцире удобно играть в настолки.',
    isPurchasable: true,
    cost: 50,
  ),
  6: const SkinDialog(
    6,
    'Красный ниндзя',
    'Любит саи.',
    isPurchasable: true,
    cost: 30,
  ),
  7: const SkinDialog(
    7,
    'Синий ниндзя',
    'Любит мечи.',
    isPurchasable: true,
    cost: 30,
  ),
  8: const SkinDialog(
    8,
    'Фиолетовый ниндзя',
    'Любит посох.',
    isPurchasable: true,
    cost: 30,
  ),
  9: const SkinDialog(
    9,
    'Оранжевый ниндзя',
    'Любит нунчаки.',
    isPurchasable: true,
    cost: 30,
  ),
  10: const SkinDialog(
    10,
    'Путешественник',
    '18°56\'19.0"S 47°31\'17.0"E',
    isPurchasable: false,
  ),
  11: const SkinDialog(
    11,
    'Авокадо',
    'Да, это квадратное авокадо. И что с того?',
    isPurchasable: true,
    cost: 50,
  ),
  12: const SkinDialog(
    12,
    'Половинка арбуза',
    'Всего половинка, но зато продаётся.',
    isPurchasable: true,
    cost: 50,
  ),
  13: const SkinDialog(
    13,
    'Слизень',
    'Как ни странно, нашёл применение в механизмах, работающих на волшебной пыли красного цвета.',
    isPurchasable: true,
    cost: 50,
  ),
  14: const SkinDialog(
    14,
    'Радуга',
    'Говорят, что там, где она начинается, спрятан горшок с осколками.',
    isPurchasable: true,
    cost: 50,
  ),
  15: const SkinDialog(
    15,
    'Тыква',
    'Хочет быть лучше арбуза. Но у неё все равно не получится!',
    isPurchasable: true,
    cost: 50,
  ),
  16: const SkinDialog(
    16,
    'Дух случайности',
    'Случайным образом принимает вид одного из открытых скинов.',
    isPurchasable: true,
    cost: 100,
  ),
  17: const SkinDialog(
    17,
    'Создатель',
    'Возможно, кто-то сможет рассказать об этом больше.',
    isPurchasable: false,
  ),
  18: const SkinDialog(
    18,
    'Ёлочный шарик',
    'Праздник к нам приходит.',
    isPurchasable: false,
  ),
  19: const SkinDialog(
    19,
    'Пряничный человечек',
    'Теперь имбирный!',
    isPurchasable: true,
    cost: 50,
  ),
  20: const SkinDialog(
    20,
    'Снеговик',
    'К сожалению, в хранилище не нашлось ни одной моркови, поэтому его нос сделан из тыквы.',
    isPurchasable: true,
    cost: 50,
  ),
  21: const SkinDialog(
    21,
    'Киви',
    'Был осужден полицией моды за слишком толстую кожуру и большое количество косточек.',
    isPurchasable: true,
    cost: 50,
  ),
  22: const SkinDialog(
    22,
    'Ядерный авокадо',
    'Что будет, если нажать на большую красную кнопку?',
    isPurchasable: true,
    cost: 50,
  ),
  23: const SkinDialog(
    23,
    'Кубист',
    'Проверь свои навыки пиксель-арта! Подсказка: 8 на 8, чёрно-зелёный и взрывается. Назови в честь любимой игры. Да, и не забудь сохранить!',
    isPurchasable: false,
  ),
  24: const SkinDialog(
    24,
    'Цезарь',
    'Этот секрет надёжно спрятан на одном из уровней кампании.',
    isPurchasable: false,
  ),
  25: const SkinDialog(
    25,
    'Силовое поле',
    'Обычно пульсирует, но только не в пошаговое игре.',
    isPurchasable: true,
    cost: 30,
  ),
  26: const SkinDialog(
    26,
    'Невероятный',
    'Награда за получение более 9000 очков в бесконечном режиме.',
    isPurchasable: false,
  ),
  27: const SkinDialog(
    27,
    'Предатель',
    'На самом деле, он не может взаимодействовать с механизмами, но очень хорошо притворяется.',
    isPurchasable: true,
    cost: 100,
  ),
  28: const SkinDialog(
    28,
    'Золотой арбуз',
    'Награда за нахождение нереализованной возможности во время бета-теста. Впрочем, всегда можно найти бета-тестера и попросить у него код...',
    isPurchasable: false,
  ),
  29: const SkinDialog(
    29,
    'Исследователь',
    'Пойти не туда.',
    isPurchasable: false,
  ),
  30: const SkinDialog(
    30,
    'Красная карамель',
    'Для тех, кому арбуз показался недостаточно сладким.',
    isPurchasable: true,
    cost: 50,
  ),
  31: const SkinDialog(
    31,
    'Зелёная карамель',
    'Для тех, кому арбуз показался недостаточно сладким и зелёным.',
    isPurchasable: true,
    cost: 50,
  ),
  32: const SkinDialog(
    32,
    'Новичок',
    'Награда за прохождение кампании "Первые шаги"',
    isPurchasable: false,
  ),
};

Map<int, SkinDialog> arrowMobSkinDialogs = {
  0: SkinDialog(
    0,
    'skin1_0_name'.tr(),
    'skin1_0_desc'.tr(),
    isPurchasable: false,
    type: 1,
  ),
  1: SkinDialog(
    1,
    'skin1_1_name'.tr(),
    'skin1_1_desc'.tr(),
    isPurchasable: true,
    cost: 30,
    type: 1,
  ),
  2: SkinDialog(
    2,
    'skin1_2_name'.tr(),
    'skin1_2_desc'.tr(),
    isPurchasable: true,
    cost: 30,
    type: 1,
  ),
  3: SkinDialog(
    3,
    'skin1_3_name'.tr(),
    'skin1_3_desc'.tr(),
    isPurchasable: true,
    cost: 100,
    type: 1,
  ),
  4: SkinDialog(
    4,
    'skin1_4_name'.tr(),
    'skin1_4_desc'.tr(),
    isPurchasable: true,
    cost: 100,
    type: 1,
  ),
  5: SkinDialog(
    5,
    'skin1_5_name'.tr(),
    'skin1_5_desc'.tr(),
    isPurchasable: true,
    cost: 100,
    type: 1,
  ),
};

Map<int, SkinDialog> borderSkinDialogs = {
  0: SkinDialog(
    0,
    'skin2_0_name'.tr(),
    'skin2_0_desc'.tr(),
    isPurchasable: false,
    type: 2,
  ),
  1: SkinDialog(
    1,
    'skin2_1_name'.tr(),
    'skin2_1_desc'.tr(),
    isPurchasable: true,
    cost: 30,
    type: 2,
  ),
  2: SkinDialog(
    2,
    'skin2_2_name'.tr(),
    'skin2_2_desc'.tr(),
    isPurchasable: true,
    cost: 30,
    type: 2,
  ),
  3: SkinDialog(
    3,
    'skin2_3_name'.tr(),
    'skin2_3_desc'.tr(),
    isPurchasable: true,
    cost: 100,
    type: 2,
  ),
};

class SkinDialog extends StatelessWidget {
  final int type;
  final int id;
  final bool isPurchasable;
  final int cost;
  final String title;
  final String description;

  const SkinDialog(this.id, this.title, this.description,
      {this.isPurchasable = false, this.cost = 0, this.type = 0, Key? key})
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
      actions: isPurchasable
          ? [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                      onPressed: () {
                        _buySkin(type: type, id: id, cost: cost);
                        Navigator.pop(context);
                      },
                      icon: const ShardIcon(),
                      label: Text(
                        '$cost',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      )),
                ],
              ),
            ]
          : [],
    );
  }
}

class SkinSelector extends StatelessWidget {
  final int type;
  final int id;
  final bool locked;
  final bool selected;

  const SkinSelector(this.id, this.locked, this.type,
      {this.selected = false, Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    if (locked) {
      return Padding(
        padding: EdgeInsets.all(width / 12),
        child: GestureDetector(
          onTap: () => _showOnBuyDialog(context, false),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 4,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(child: _getSkin(type, id)),
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    Icons.lock_rounded,
                    size: 32,
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          _changeSkin(type: type, id: id);
          if (selected) {
            _showOnBuyDialog(context, true);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            selected
                ? Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 4,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                : Container(),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 4,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              width: 64,
              height: 64,
              child: _getSkin(type, id),
            )
          ],
        ),
      );
    }
  }

  Future _showOnBuyDialog(BuildContext context, [bool selected = false]) {
    if (!selected) {
      return showDialog(
          context: context,
          builder: (BuildContext context) =>
              _getSkinDialogMap(type)[id] ?? const AlertDialog());
    } else {
      return showDialog(
          context: context,
          builder: (BuildContext context) => SkinDialog(
              id,
              _getSkinDialogMap(type)[id]!.title,
              _getSkinDialogMap(type)[id]!.description,
              type: type,
              isPurchasable: false));
    }
  }
}

class ShardIcon extends StatelessWidget {
  const ShardIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
        shaderCallback: (bounds) =>
            LinearGradient(colors: [Colors.purple[400]!, Colors.purple[600]!])
                .createShader(bounds),
        child: const Icon(
          Icons.play_arrow_outlined,
          color: Colors.white,
          size: 24,
        ));
  }
}

Widget _getSkin(int type, int id) {
  switch (type) {
    case 0:
      return getPlayerImpression(id, preview: true);
    case 1:
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: getArrowMobImpression(
          id,
          Directions.right,
          skinSize,
          preview: true,
        ),
      );
    case 2:
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: getBorderImpression(
          id,
          6,
          skinSize,
        ),
      );
    default:
      throw Exception('There is no skin with type $type');
  }
}

ValueNotifier<int> _getTabNotifier(int id) {
  switch (id) {
    case 0:
      return charId;
    case 1:
      return arrowMobId;
    case 2:
      return borderId;
    default:
      throw Exception('There is no Tab with id $id');
  }
}

Map<int, SkinDialog> _getSkinDialogMap(type) {
  switch (type) {
    case 0:
      return charSkinDialogs;
    case 1:
      return arrowMobSkinDialogs;
    case 2:
      return borderSkinDialogs;
    default:
      throw Exception('There is no Map of dialogs with type $type');
  }
}

void _changeSkin({required int type, required int id}) {
  switch (type) {
    case 0:
      charId.value = id;
      stats.charSkinId = id;
      stats.writeStats();
      break;
    case 1:
      arrowMobId.value = id;
      stats.arrowMobSkinId = id;
      stats.writeStats();
      break;
    case 2:
      borderId.value = id;
      stats.borderSkinId = id;
      stats.writeStats();
      break;
  }
}

void _buySkin({
  required int type,
  required int id,
  required int cost,
}) {
  void _handleSkinTransaction(int cost) {
    shards.value -= cost;
    stats.coins -= cost;
    stats.writeStats();
  }

  switch (type) {
    case 0:
      if (shards.value - cost >= 0) {
        charSkinsOwn.value[id] = 'true';
        charId.value = id;
        stats.charSkinsOwn = charSkinsOwn.value;
        stats.charSkinId = id;
        _handleSkinTransaction(cost);
      }
      break;
    case 1:
      if (shards.value - cost >= 0) {
        arrowMobSkinsOwn.value[id] = 'true';
        arrowMobId.value = id;
        stats.arrowMobSkinsOwn = arrowMobSkinsOwn.value;
        stats.arrowMobSkinId = id;
        _handleSkinTransaction(cost);
      }
      break;
    case 2:
      if (shards.value - cost >= 0) {
        borderSkinsOwn.value[id] = 'true';
        borderId.value = id;
        stats.borderSkinsOwn = borderSkinsOwn.value;
        stats.borderSkinId = id;
        _handleSkinTransaction(cost);
      }
      break;
    default:
  }
}
