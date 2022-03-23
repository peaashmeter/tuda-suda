import 'package:flutter/material.dart';
import 'package:logicgame/global_stats.dart' as stats;
import 'endless_stats.dart' as endless_stats;
import 'package:logicgame/menu/menu.dart';

import 'endless_game.dart' as endless;
import 'generator.dart' as generator;

class Interlevel extends StatefulWidget {
  final int passed;
  final int levelScore;
  final int totalScore;
  final int health;
  final int coins;
  const Interlevel(
      {Key? key,
      required this.passed,
      required this.levelScore,
      required this.totalScore,
      required this.health,
      required this.coins})
      : super(key: key);

  @override
  State<Interlevel> createState() => _InterlevelState();
}

class _InterlevelState extends State<Interlevel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var penalty = (widget.levelScore * (3 - widget.health)) ~/ 3;
    var newTotalScore = widget.totalScore + widget.levelScore - penalty;

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      endless_stats.levelsPassed++;

      if (widget.passed > endless_stats.maxRow) {
        endless_stats.maxRow = widget.passed;
      }

      stats.coins = stats.coins + widget.coins;
      endless_stats.writeStats();
      stats.writeStats();
    });

    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blueGrey[900],
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Уровень пройден!',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  CoinDisplay(widget.coins)
                ]),
            automaticallyImplyLeading: false,
            leading: null,
          ),
          body: Container(
              color: Colors.blueGrey[900],
              child: AnimatedScoreText(
                passed: widget.passed,
                levelScore: widget.levelScore,
                penalty: penalty,
                newTotalScore: newTotalScore,
                coins: widget.coins,
              )),
        ),
        onWillPop: () async => false);
  }

  void toMenu(context) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (globalContext) => const Menu()));
  }

  void nextLevel(context, newTotalScore) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (globalContext) => endless.EndlessGame(
                level: generator.generateLevel(difficulty: widget.passed),
                levelScore: generator.levelScore,
                passed: widget.passed,
                totalScore: newTotalScore)));
  }
}

class CoinDisplay extends StatefulWidget {
  final int coins;
  const CoinDisplay(this.coins, {Key? key}) : super(key: key);

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
          child: Text('${stats.coins}',
              style: const TextStyle(color: Colors.white, fontSize: 20)),
        )
      ]),
    );
  }
}

class AnimatedScoreText extends StatefulWidget {
  final int passed;
  final int levelScore;
  final int penalty;
  final int newTotalScore;
  final int coins;
  const AnimatedScoreText(
      {Key? key,
      required this.passed,
      required this.levelScore,
      required this.penalty,
      required this.newTotalScore,
      required this.coins})
      : super(key: key);

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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: animation.value,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Пройдено уровней: ',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text('${(animation.value * (widget.passed)).toInt()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Счет за уровень: ',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text('${(animation.value * widget.levelScore).toInt()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Штраф за попытки: ',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text('${(animation.value * widget.penalty).toInt()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Собрано монет: ',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text('${(animation.value * widget.coins).toInt()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итоговый счет: ',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    Text('${(animation.value * widget.newTotalScore).toInt()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20)),
                  ],
                ),
              ),
            ],
          ),
          const Expanded(flex: 4, child: SizedBox.shrink()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                  onPressed: () => toMenu(context),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Сдаться',
                      style: TextStyle(color: Colors.white, fontSize: 20))),
              ElevatedButton.icon(
                  onPressed: () => nextLevel(context, widget.newTotalScore),
                  icon: const Icon(Icons.forward_rounded),
                  label: const Text('Продолжить',
                      style: TextStyle(color: Colors.white, fontSize: 20))),
            ],
          ),
          const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  void toMenu(context) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (globalContext) => const Menu()));
  }

  void nextLevel(context, newTotalScore) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (globalContext) => endless.EndlessGame(
                level: generator.generateLevel(difficulty: widget.passed),
                levelScore: generator.levelScore,
                passed: widget.passed,
                totalScore: newTotalScore)));
  }
}
