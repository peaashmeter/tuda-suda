import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'settings.dart' as settings;

late AudioCache audio;

void initAudio() {
  audio = AudioCache(prefix: 'assets/sounds/');
  audio.loadAll([
    'move0.wav',
    'move1.wav',
    'move2.wav',
    'move3.wav',
    'win.wav',
    'coin.wav',
    'lose.wav',
    'switcher.wav'
  ]);
}

enum Sounds {
  coin,
  switcher,
  lose,
  win,
}

List<Sounds> soundQueue = [];

void playCoinSound() {
  if (settings.isSound) {
    audio.play('coin.wav', volume: 0.8);
  }
}

void playSwitcherSound() {
  if (settings.isSound) {
    audio.play('switcher.wav', volume: 0.8);
  }
}

void playLoseSound() {
  if (settings.isSound) {
    audio.play('lose.wav', volume: 0.8);
  }
}

void playMoveSound() {
  // if (settings.isSound) {
  //   int i = Random().nextInt(4);
  //   audio.play('move$i.wav', volume: 0.8);
  // }
}

void playWinSound() {
  if (settings.isSound) {
    audio.play('win.wav', volume: 0.8);
  }
}
