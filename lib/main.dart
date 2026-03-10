import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/screens/home_screen.dart';
import 'package:pixelplay/screens/main_shell.dart';

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
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF00E676),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          brightness: Brightness.dark,
          surface: Colors.black,
          onSurface: Colors.white,
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF00E676),
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
