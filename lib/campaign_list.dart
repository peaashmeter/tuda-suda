import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logicgame/level_list.dart';
import 'package:logicgame/level_loader.dart';
import 'package:logicgame/menu/menu.dart';
import 'global_stats.dart' as stats;

class CampaignList extends StatelessWidget {
  const CampaignList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Menu()));
        return false;
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
            title: Text("camp_title".tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20))),
        body: Container(
          color: Colors.black,
          child: ListView(children: [
            CampaignTab(
                picture: Icon(
                  Icons.arrow_forward_rounded,
                  color: stats.c1Reward ? Colors.blue[900] : Colors.black,
                ),
                title: 'camp_1'.tr(),
                index: 1),
            CampaignTab(
                picture: const Icon(Icons.bolt_rounded),
                title: 'camp_2'.tr(),
                index: 2),
            CampaignTab(
                picture: const Icon(Icons.alarm_rounded),
                title: 'camp_3'.tr(),
                index: -1)
          ]),
        ),
      ),
    );
  }
}

class CampaignTab extends StatelessWidget {
  final Icon picture;
  final String title;
  final int index;
  const CampaignTab(
      {Key? key,
      required this.picture,
      required this.title,
      required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (index != -1) {
          loadLevels(index).then((levels) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => WillPopScope(
                        onWillPop: () async {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CampaignList()));
                          return false;
                        },
                        child: Scaffold(
                            appBar: AppBar(
                                leading: IconButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const CampaignList()));
                                    },
                                    icon: const Icon(Icons.arrow_back_rounded)),
                                backgroundColor: Colors.blueGrey[900],
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                )),
                            body: LevelList(
                              levels: levels,
                              isCampaign: true,
                              index: index,
                            )),
                      ))));
        } else {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Colors.blueGrey[900],
                  title: const Text(
                    'Будет позже!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  // content: const Text(
                  //   'Спасибо за участие в бета-тесте! Используй код \'GOLDENWATERMELON\'.',
                  //   style: TextStyle(color: Colors.white, fontSize: 20),
                  // )
                );
              });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    gradient: LinearGradient(
                        colors: [Color(0xFF263238), Color(0xFF37474F)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                          7,
                          (i) => (i + 1) % 2 == 0
                              ? const SizedBox.shrink()
                              : picture),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          7,
                          (i) => (i + 1) % 2 == 1
                              ? const SizedBox.shrink()
                              : picture),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                          7,
                          (i) => (i + 1) % 2 == 0
                              ? const SizedBox.shrink()
                              : picture),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          7,
                          (i) => (i + 1) % 2 == 1
                              ? const SizedBox.shrink()
                              : picture),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                          7,
                          (i) => (i + 1) % 2 == 0
                              ? const SizedBox.shrink()
                              : picture),
                    ),
                  ],
                )),
            Positioned.fill(
              child: Center(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          shadows: [
                            Shadow(
                              offset: Offset(3, 3),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ]))),
            )
          ],
        ),
      ),
    );
  }
}
