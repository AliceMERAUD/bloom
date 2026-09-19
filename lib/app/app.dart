import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import 'theme.dart';

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom',
      debugShowCheckedModeBanner: false,
      theme: BloomTheme.light(),
      home: const HomeScreen(),
    );
  }
}