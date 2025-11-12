// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../enums.dart';
import '../widgets/sidebar_menu.dart';
import 'dashboard_page.dart';
import 'pedidos_page.dart';
import 'criar_link_page.dart';
import 'conferir_pagamentos_page.dart';
import 'motoboys_page.dart';
import 'atualizacoes_page.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MenuItem _selected = MenuItem.dashboard;

  void _select(MenuItem item) => setState(() => _selected = item);

  Widget _content() {
    // Usando if/else para compatibilidade com Dart < 3.0
    if (_selected == MenuItem.dashboard) return const DashboardPage();
    if (_selected == MenuItem.pedidos) return const PedidosPage();
    if (_selected == MenuItem.criarLink) return const CriarLinkPage();
    if (_selected == MenuItem.verPagamentos) return const ConferirPagamentosPage();
    if (_selected == MenuItem.motoboys) return const MotoboysPage();
    if (_selected == MenuItem.atualizacoes) return const AtualizacoesPage();
    return const DashboardPage(); // fallback
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          SidebarMenu(
            selectedMenu: _selected,
            onMenuItemSelected: _select,
            onLogout: () {
              auth.logout().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              });
            },
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }
}