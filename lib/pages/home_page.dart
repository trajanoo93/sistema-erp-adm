// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../enums.dart';
import 'dashboard_page.dart';
import 'pedidos_page.dart';
import 'criar_pedido_page.dart';
import 'motoboys_page.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MenuItem _selectedMenu = MenuItem.dashboard;

  Widget _getPage(MenuItem item) {
    switch (item) {
      case MenuItem.dashboard:
        return const DashboardPage();
      case MenuItem.pedidos:
        return const PedidosPage();
      case MenuItem.novoPedido:
        return const CriarPedidoPage();
      case MenuItem.motoboys:
        return const MotoboysPage();
      case MenuItem.atualizacoes:
        return const Center(child: Text('Atualizações'));
      case MenuItem.criarLink:
      case MenuItem.verPagamentos:
      case MenuItem.pagamentos:
        return const Center(child: Text('Pagamentos - Em desenvolvimento'));
      default:
        return const DashboardPage();
    }
  }

  void _handleLogout(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Erro: Usuário não autenticado')));
    }

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            selectedMenu: _selectedMenu,
            onMenuItemSelected: (menuItem) {
              setState(() => _selectedMenu = menuItem);
            },
            userName: user.nome.split(' ').first,
            userUnit: user.unidade,
            onLogout: () => _handleLogout(context),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.black12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _getPage(_selectedMenu).copyWithKey(ValueKey(_selectedMenu)),
            ),
          ),
        ],
      ),
    );
  }
}

// Extensão para adicionar key ao widget (necessário para AnimatedSwitcher)
extension WidgetKey on Widget {
  Widget copyWithKey(Key key) {
    return Container(key: key, child: this);
  }
}