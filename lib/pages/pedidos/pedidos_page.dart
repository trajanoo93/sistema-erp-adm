// lib/pages/pedidos/pedidos_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../design_system.dart';
import 'controllers/pedidos_controller.dart';
import 'widgets/stats_header.dart';
import 'widgets/filtros_bar.dart';
import 'widgets/pedido_card.dart';
import 'modals/detalhes_pedido_modal.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  late final PedidosController _controller;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = PedidosController();
    _searchController.addListener(() {
      setState(() {
        _controller.setBusca(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          // Header com estatísticas
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => StatsHeader(controller: _controller),
          ),
          
          // Barra de filtros
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => FiltrosBar(
              controller: _controller,
              searchController: _searchController,
            ),
          ),
          
          // Lista de pedidos
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildPedidosList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.buildQuery().snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator(size: 40));
        }

        // Erro
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar pedidos', style: AppTypography.cardTitle),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filtrar pedidos
        final docs = snapshot.data!.docs;
        final filtered = _controller.filtrarPedidos(docs);

        // Estado vazio
        if (filtered.isEmpty) {
          return AppEmptyState(
            icon: Icons.inbox_rounded,
            title: 'Nenhum pedido encontrado',
            message: _controller.busca.isNotEmpty ||
                    _controller.statusFiltros.isNotEmpty ||
                    _controller.pagamentoFiltros.isNotEmpty
                ? 'Tente ajustar os filtros para encontrar o que procura'
                : 'Ainda não há pedidos registrados para este período',
          );
        }

        // Lista de pedidos
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return PedidoCard(
              data: data,
              pedidoId: doc.id,
              controller: _controller,
              onTap: () => _abrirDetalhes(data, doc.id),
              onAtualizado: () => setState(() {}),
            );
          },
        );
      },
    );
  }

  void _abrirDetalhes(Map<String, dynamic> data, String pedidoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalhesPedidoModal(
        data: data,
        pedidoId: pedidoId,
        controller: _controller,
        onAtualizado: () => setState(() {}),
      ),
    );
  }
}