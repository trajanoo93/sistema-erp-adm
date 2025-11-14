// lib/pages/pedidos/widgets/filtros_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../design_system.dart';
import '../controllers/pedidos_controller.dart';

class FiltrosBar extends StatelessWidget {
  final PedidosController controller;
  final TextEditingController searchController;

  const FiltrosBar({
    Key? key,
    required this.controller,
    required this.searchController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Column(
        children: [
          // LINHA 1: Busca
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID, nome, bairro...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: controller.busca.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                searchController.clear();
                                controller.setBusca('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // LINHA 2: Filtros
          Row(
            children: [
              // CD
              Expanded(
                flex: 2,
                child: _buildDropdownFilter(
                  icon: Icons.warehouse_rounded,
                  value: controller.cdFiltro,
                  items: controller.cds,
                  onChanged: (v) => controller.setCdFiltro(v!),
                ),
              ),
              const SizedBox(width: 8),
              
              // Data Inicial
              Expanded(
                flex: 2,
                child: _buildDateFilter(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  label: controller.dataInicial == null
                      ? 'Data inicial'
                      : DateFormat('dd/MM/yy').format(controller.dataInicial!),
                  onTap: () => _selecionarData(context, true),
                ),
              ),
              const SizedBox(width: 8),
              
              // Data Final
              Expanded(
                flex: 2,
                child: _buildDateFilter(
                  context: context,
                  icon: Icons.event_rounded,
                  label: controller.dataFinal == null
                      ? 'Data final'
                      : DateFormat('dd/MM/yy').format(controller.dataFinal!),
                  onTap: () => _selecionarData(context, false),
                ),
              ),
              const SizedBox(width: 8),
              
              // Status
              Expanded(
                flex: 2,
                child: _buildMultiSelectFilter(
                  context: context,
                  icon: Icons.filter_list_rounded,
                  label: controller.statusFiltros.isEmpty
                      ? 'Todos os status'
                      : '${controller.statusFiltros.length} status',
                  items: controller.statusList,
                  selectedItems: controller.statusFiltros,
                  onToggle: (item) => controller.toggleStatusFiltro(item),
                  getColor: (item) => controller.getStatusColor(item),
                  getIcon: (item) => controller.getStatusIcon(item),
                ),
              ),
              const SizedBox(width: 8),
              
              // NOVO: Filtro de Pagamento
              Expanded(
                flex: 2,
                child: _buildMultiSelectFilter(
                  context: context,
                  icon: Icons.payment_rounded,
                  label: controller.pagamentoFiltros.isEmpty
                      ? 'Pagamento'
                      : '${controller.pagamentoFiltros.length} método${controller.pagamentoFiltros.length > 1 ? 's' : ''}',
                  items: controller.pagamentosList,
                  selectedItems: controller.pagamentoFiltros,
                  onToggle: (item) => controller.togglePagamentoFiltro(item),
                  getColor: (item) => _getPaymentColor(item),
                  getIcon: (item) => controller.getPaymentIcon(item),
                ),
              ),
              const SizedBox(width: 8),
              
              // Limpar Filtros
              if (controller.busca.isNotEmpty ||
                  controller.statusFiltros.isNotEmpty ||
                  controller.pagamentoFiltros.isNotEmpty)
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.clear_all_rounded, color: AppColors.error, size: 20),
                    onPressed: () {
                      searchController.clear();
                      controller.limparFiltros();
                    },
                    tooltip: 'Limpar Filtros',
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, style: AppTypography.bodySmall),
                      ))
                  .toList(),
              onChanged: onChanged,
              underline: const SizedBox.shrink(),
              isDense: true,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectFilter({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<String> items,
    required Set<String> selectedItems,
    required Function(String) onToggle,
    required Color Function(String) getColor,
    required IconData Function(String) getIcon,
  }) {
    return PopupMenuButton<String>(
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtrar', style: AppTypography.label),
                  TextButton(
                    onPressed: () {
                      selectedItems.clear();
                      controller.notifyListeners();
                      Navigator.pop(context);
                    },
                    child: Text('Limpar', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
              const Divider(height: 8),
            ],
          ),
        ),
        ...items.map((item) {
          return PopupMenuItem<String>(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              // CORREÇÃO: Atualizar no próximo frame para permitir que o menu feche
              Future.delayed(Duration.zero, () {
                onToggle(item);
              });
            },
            child: StatefulBuilder(
              builder: (context, setStateMenu) {
                final isSelected = selectedItems.contains(item);
                final color = getColor(item);
                
                return Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? color : AppColors.borderMedium,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Icon(getIcon(item), size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: AppTypography.bodySmall)),
                  ],
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Future<void> _selecionarData(BuildContext context, bool isInicial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isInicial
          ? (controller.dataInicial ?? DateTime.now())
          : (controller.dataFinal ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      if (isInicial) {
        controller.setDataInicial(DateTime(date.year, date.month, date.day));
      } else {
        controller.setDataFinal(DateTime(date.year, date.month, date.day, 23, 59, 59));
      }
    }
  }

  Color _getPaymentColor(String method) {
    return switch (method) {
      'Pix' => const Color(0xFF00BCD4),
      'Cartão' => AppColors.primary,
      'Crédito Site' => const Color(0xFFFF9800),
      'V.A.' => const Color(0xFF4CAF50),
      _ => AppColors.textSecondary,
    };
  }
}