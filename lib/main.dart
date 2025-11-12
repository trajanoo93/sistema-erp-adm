// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'provider/auth_provider.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';

RandomAccessFile? _lock;

Future<bool> _lockInstance() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/ERPUnificado');
    if (!appDir.existsSync()) appDir.createSync(recursive: true);
    final file = File('${appDir.path}/app.lock');
    _lock = await file.open(mode: FileMode.write);
    await _lock!.lock(FileLock.exclusive);
    return true;
  } catch (_) {
    await _lock?.close();
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows && !await _lockInstance()) exit(0);

  // INICIALIZAÇÃO 100% SEGURA (NUNCA CRASHA)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase inicializado com sucesso');
    } else {
      debugPrint('Firebase já estava inicializado');
    }
  } catch (e) {
    // IGNORA apenas duplicate-app, mas loga outros erros
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('Erro crítico no Firebase: $e');
      // Não rethrow → evita tela preta
    } else {
      debugPrint('Firebase já inicializado (hot restart)');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadSavedUser(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Pedidos | Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const HomePage() : const AuthPage();
        },
      ),
    );
  }
}