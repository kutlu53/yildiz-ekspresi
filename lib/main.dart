import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/story/story_flow.dart';

void main() {
  runApp(const YildizEkspresiApp());
}

class YildizEkspresiApp extends StatelessWidget {
  const YildizEkspresiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yıldız Ekspresi',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5E35B1)),
        useMaterial3: true,
        visualDensity: VisualDensity.comfortable,
      ),
      home: const StoryFlow(),
    );
  }
}
