import 'package:flutter/material.dart';

import 'pages/pressao_page.dart';

class SonndaApp extends StatelessWidget {
  const SonndaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonnda - Pressao Arterial',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PressaoPage(),
    );
  }
}
