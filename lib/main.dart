// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_erp_cd/provider/auth_provider.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';  // ← com sidebar

RandomAccessFile? _instanceLock;

Future<bool> _acquireSingleInstanceLock() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/ERPUnificado');
    if (!appDir.existsSync()) appDir.createSync(recursive: true);
    final lockFile = File('${appDir.path}/app.lock');
    _instanceLock = await lockFile.open(mode: FileMode.write);
    await _instanceLock!.lock(FileLock.exclusive);
    return true;
  } catch (_) {
    await _instanceLock?.close();
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    final ok = await _acquireSingleInstanceLock();
    if (!ok) exit(0);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadSavedUser(),  // ← FUNCIONA
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Unificado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Consumer<AuthProvider>(  // ← FUNCIONA
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const HomePage() : const AuthPage();
        },
      ),
    );
  }
}