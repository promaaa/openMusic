// lib/main.dart
/// OpenMusic - Spotify Playlist Downloader
/// No Spotify account required - just paste your playlist link!

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const ProviderScope(child: OpenMusicApp()));
}

class OpenMusicApp extends StatelessWidget {
  const OpenMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenMusic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954), // Spotify green
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const HomePage(),
    );
  }
}
