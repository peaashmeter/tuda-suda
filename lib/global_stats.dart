import 'package:shared_preferences/shared_preferences.dart';

late int coins;
late int charSkinId;
late int arrowMobSkinId;
late int borderSkinId;

const int charSkinsInGame = 33;
const int arrowMobSkinsInGame = 6;
const int borderSkinsInGame = 4;

late List<String> charSkinsOwn;
late List<String> arrowMobSkinsOwn;
late List<String> borderSkinsOwn;

late int c1Unlocked;
late int c2Unlocked;

late SharedPreferences prefs;

late bool c1Reward = false;

late bool removeAds = false;

void writeStats() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('coins', coins);
  await prefs.setInt('charSkin', charSkinId);
  await prefs.setInt('arrowMobSkin', arrowMobSkinId);
  await prefs.setInt('borderSkin', borderSkinId);
  await prefs.setInt('c1Unlocked', c1Unlocked);
  await prefs.setBool('c1Reward', c1Reward);
  await prefs.setInt('c2Unlocked', c1Unlocked);

  await prefs.setBool('removeAds', removeAds);
  await prefs.setStringList('charSkinsOwn', charSkinsOwn);
  await prefs.setStringList('arrowMobSkinsOwn', arrowMobSkinsOwn);
  await prefs.setStringList('borderSkinsOwn', borderSkinsOwn);
}

void loadStats() async {
  prefs = await SharedPreferences.getInstance();
  coins = prefs.getInt('coins') ?? 0;
  charSkinId = prefs.getInt('charSkin') ?? 0;
  arrowMobSkinId = prefs.getInt('arrowMobSkin') ?? 0;
  borderSkinId = prefs.getInt('borderSkin') ?? 0;
  c1Unlocked = prefs.getInt('c1Unlocked') ?? 0;
  c1Reward = c1Unlocked == 30 ? true : false;

  c2Unlocked = -1; //prefs.getInt('c2Unlocked') ?? -1;

  removeAds = prefs.getBool('removeAds') ?? false;

  charSkinsOwn = _handleSkinList('charSkinsOwn', charSkinsInGame);
  arrowMobSkinsOwn = _handleSkinList('arrowMobSkinsOwn', arrowMobSkinsInGame);
  borderSkinsOwn = _handleSkinList('borderSkinsOwn', borderSkinsInGame);
}

List<String> _handleSkinList(String literal, int countOfSkins) {
  var temp = prefs.getStringList(literal);
  //testing
  //return ['true', ...List.generate(countOfSkins - 1, (index) => 'false')];
  if (temp == null) {
    return ['true', ...List.generate(countOfSkins - 1, (index) => 'false')];
  } else if (temp.length < countOfSkins) {
    return [
      ...temp,
      ...List.generate(countOfSkins - temp.length, (i) => 'false')
    ];
  } else {
    return temp;
  }
}
