import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize media_kit
  MediaKit.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProvider()),
      ],
      child: const PixelPlayApp(),
    ),
  );
}

class PixelPlayApp extends StatelessWidget {
  const PixelPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixelPlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
          secondary: const Color(0xFF00D2FF),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
