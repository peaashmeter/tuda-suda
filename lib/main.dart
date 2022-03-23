import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:logicgame/settings.dart' as settings;
import 'package:logicgame/generator/endless_stats.dart' as endless_stats;
import 'package:logicgame/global_stats.dart' as global_stats;
import 'package:logicgame/menu/menu.dart';
import 'sound_handler.dart' as audio;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  settings.loadSettings();
  endless_stats.loadStats();
  global_stats.loadStats();

  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('ru'), Locale('en')],
        path: 'assets/translations',
        startLocale: const Locale('ru'),
        fallbackLocale: const Locale('ru'),
        child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  void initState() {
    super.initState();

    audio.initAudio();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        //showPerformanceOverlay: true,
        //checkerboardOffscreenLayers: true,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: 'Tuda-Suda',
        theme: ThemeData(primarySwatch: Colors.blueGrey, fontFamily: 'Nunito'),
        home: const Menu());
  }
}
