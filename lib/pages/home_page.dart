// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sistema_erp_cd/provider/auth_provider.dart';
import '../enums.dart';
import '../widgets/sidebar_menu.dart';
import 'dashboard_page.dart';
import 'pedidos_page.dart';
import 'criar_pedido_page.dart';
import 'auth_page.dart';
import 'conferir_pagamentos_page.dart';
import 'criar_link_page.dart';
import 'motoboys_page.dart';     
import 'atualizacoes_page.dart';    

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MenuItem _selectedMenu = MenuItem.dashboard;

  void _onMenuItemSelected(MenuItem menuItem) {
    setState(() => _selectedMenu = menuItem);
  }

  Widget _buildMainContent() {
    switch (_selectedMenu) {
      case MenuItem.dashboard:
        return const DashboardPage();
      case MenuItem.pedidos:
        return const PedidosPage();
      case MenuItem.novoPedido:
        return const CriarPedidoPage();
      case MenuItem.criarLink:
        return const CriarLinkPage();
      case MenuItem.verPagamentos:
        return const ConferirPagamentosPage();
      case MenuItem.motoboys:  // ADICIONADO
        return const MotoboysPage();
      case MenuItem.atualizacoes:  // ADICIONADO
        return const AtualizacoesPage();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final unidade = auth.user?.unidade ?? 'CD';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // === SIDEBAR ===
          SidebarMenu(
            selectedMenu: _selectedMenu,
            onMenuItemSelected: _onMenuItemSelected,
            userUnit: unidade,
            onLogout: () {
              auth.logout().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              });
            },
          ),

          // === CONTEÚDO PRINCIPAL ===
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }
}