import 'package:shared_preferences/shared_preferences.dart';

late bool isMoreAnimations;
late bool isSimpleInterface; //deprecated
late bool isBackground;
late bool isDpad;
late bool isSound;

void writeSettings() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('isMoreAnimations', isMoreAnimations);
  await prefs.setBool('isSimpleInterface', isSimpleInterface);
  await prefs.setBool('isDpad', isDpad);
  await prefs.setBool('isBackground', isBackground);
  await prefs.setBool('isSound', isSound);
}

void loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  isMoreAnimations = prefs.getBool('isMoreAnimations') ?? true;
  isSimpleInterface = false;
  isDpad = prefs.getBool('isDpad') ?? false;
  isBackground = prefs.getBool('isBackground') ?? true;
  isSound = prefs.getBool('isSound') ?? true;
}
