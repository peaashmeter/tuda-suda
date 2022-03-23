import 'package:shared_preferences/shared_preferences.dart';

late int maxRow;
late int highScore;
late int levelsPassed;

late bool isPlainAvailable;
late bool isPlainChosen;

late bool isXWallAvailable;
late bool isXWallChosen;

late bool isYWallAvailable;
late bool isYWallChosen;

late bool isPlainHardAvailable;
late bool isPlainHardChosen;

late bool isYCrossAvailable;
late bool isYCrossChosen;

late bool isLaserRoomAvailable;
late bool isLaserRoomChosen;

late bool isPortalsAvailable;
late bool isPortalsChosen;

void writeStats() async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setInt('maxRow', maxRow);
  prefs.setInt('highScore', highScore);
  prefs.setInt('levelsPassed', levelsPassed);

  prefs.setBool('isPlainAvailable', isPlainAvailable);
  prefs.setBool('isPlainChosen', isPlainChosen);

  prefs.setBool('isXWallAvailable', isXWallAvailable);
  prefs.setBool('isXWallChosen', isXWallChosen);

  prefs.setBool('isYWallAvailable', isYWallAvailable);
  prefs.setBool('isYWallChosen', isYWallChosen);

  prefs.setBool('isPlainHardAvailable', isPlainHardAvailable);
  prefs.setBool('isPlainHardChosen', isPlainHardChosen);

  prefs.setBool('isYCrossAvailable', isYCrossAvailable);
  prefs.setBool('isYCrossChosen', isYCrossChosen);

  prefs.setBool('isLaserRoomAvailable', isLaserRoomAvailable);
  prefs.setBool('isLaserRoomChosen', isLaserRoomChosen);

  prefs.setBool('isPortalsAvailable', isPortalsAvailable);
  prefs.setBool('isPortalsChosen', isPortalsChosen);
}

void loadStats() async {
  final prefs = await SharedPreferences.getInstance();

  maxRow = prefs.getInt('maxRow') ?? 0;
  highScore = prefs.getInt('highScore') ?? 0;
  levelsPassed = prefs.getInt('levelsPassed') ?? 0;

  isPlainAvailable = prefs.getBool('isPlainAvailable') ?? true;
  isPlainChosen = prefs.getBool('isPlainChosen') ?? true;

  isXWallAvailable = prefs.getBool('isXWallAvailable') ?? false;
  isXWallChosen = prefs.getBool('isXWallChosen') ?? false;

  isYWallAvailable = prefs.getBool('isYWallAvailable') ?? false;
  isYWallChosen = prefs.getBool('isYWallChosen') ?? false;

  isPlainHardAvailable = prefs.getBool('isPlainHardAvailable') ?? false;
  isPlainHardChosen = prefs.getBool('isPlainHardChosen') ?? false;

  isYCrossAvailable = prefs.getBool('isYCrossAvailable') ?? false;
  isYCrossChosen = prefs.getBool('isYCrossChosen') ?? false;

  isLaserRoomAvailable = prefs.getBool('isLaserRoomAvailable') ?? false;
  isLaserRoomChosen = prefs.getBool('isLaserRoomChosen') ?? false;

  isPortalsAvailable = prefs.getBool('isPortalsAvailable') ?? false;
  isPortalsChosen = prefs.getBool('isPortalsChosen') ?? false;
}
