// lib/pages/auth_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sistema_erp_cd/provider/auth_provider.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);
  @override State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _error;
  late AnimationController _controllerAnim;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controllerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controllerAnim, curve: Curves.easeInOut),
    );
    _controllerAnim.forward();
  }

  @override
  void dispose() {
    _controllerAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Tom suave bege/creme
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(48),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Hero(
                  tag: 'logo',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/icon/GO-logo.png', height: 64),
                  ),
                ),
                const SizedBox(height: 28),

                // Título
                Text(
                  'Sistema Delivery #GO!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE67E22), // Tom laranja mais suave
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ao Gosto Carnes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de código
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Digite seu código',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAF6F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),

                // Erro
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Botão Entrar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final code = int.tryParse(_controller.text);
                      if (code == null) {
                        setState(() => _error = 'Código inválido');
                        return;
                      }
                      try {
                        await Provider.of<AuthProvider>(context, listen: false).login(code);
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const HomePage(),
                              transitionDuration: const Duration(milliseconds: 400),
                              transitionsBuilder: (_, anim, __, child) {
                                return FadeTransition(opacity: anim, child: child);
                              },
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ENTRAR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Versão 1.4.3',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}