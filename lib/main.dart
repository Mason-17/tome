import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/document_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TomeApp());
}

class TomeApp extends StatelessWidget {
  const TomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DocumentProvider()..loadRecentFiles(),
      child: MaterialApp(
        title: 'Tome - Markdown Editor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.urbanist().fontFamily,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.urbanist().fontFamily,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}