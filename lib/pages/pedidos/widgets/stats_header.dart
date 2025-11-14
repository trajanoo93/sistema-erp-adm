// lib/pages/pedidos/widgets/stats_header.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../design_system.dart';
import '../controllers/pedidos_controller.dart';

class StatsHeader extends StatelessWidget {
  final PedidosController controller;

  const StatsHeader({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          // Logo + Título
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOpacity12,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primaryOpacity25),
            ),
            child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestão de Pedidos', style: AppTypography.sectionTitle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sistema online • Atualização em tempo real',
                      style: AppTypography.caption.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats em tempo real
          StreamBuilder<QuerySnapshot>(
            stream: controller.buildQuery().snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final docs = snapshot.data!.docs;
              final total = docs.length;
              final pendentes = docs.where((d) {
                final status = (d.data() as Map)['status'] ?? '';
                return ['Pendente', 'Processando', 'Registrado'].contains(status);
              }).length;
              final saiuEntrega = docs.where((d) {
                final status = (d.data() as Map)['status'] ?? '';
                return status == 'Saiu pra Entrega';
              }).length;
              final concluidos = docs.where((d) {
                final status = (d.data() as Map)['status'] ?? '';
                return status == 'Concluído';
              }).length;

              return Row(
                children: [
                  _buildStatCard(
                    label: 'Total',
                    value: total.toString(),
                    icon: Icons.shopping_cart_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Pendentes',
                    value: pendentes.toString(),
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Em Rota',
                    value: saiuEntrega.toString(),
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    label: 'Concluídos',
                    value: concluidos.toString(),
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF009688),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.cardTitle.copyWith(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}