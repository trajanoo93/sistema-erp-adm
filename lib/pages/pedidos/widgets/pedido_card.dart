// lib/pages/pedidos/widgets/pedido_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../design_system.dart';
import '../controllers/pedidos_controller.dart';

class PedidoCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String pedidoId;
  final PedidosController controller;
  final VoidCallback onTap;
  final VoidCallback onAtualizado;

  const PedidoCard({
    Key? key,
    required this.data,
    required this.pedidoId,
    required this.controller,
    required this.onTap,
    required this.onAtualizado,
  }) : super(key: key);

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] == '-' ? 'Processando' : (widget.data['status'] ?? 'Processando');
    final color = widget.controller.getStatusColor(status);
    final tipoEntrega = widget.data['tipo_entrega']?.toString() ?? 'delivery';
    
    final cliente = widget.data['cliente'] as Map<String, dynamic>?;
    final endereco = widget.data['endereco'] as Map<String, dynamic>?;
    final pagamento = widget.data['pagamento'] as Map<String, dynamic>?;
    final agendamento = widget.data['agendamento'] as Map<String, dynamic>?;
    
    final slot = agendamento?['janela_texto'] ?? 'Sem slot';
    final bairro = endereco?['bairro'] ?? 'Bairro não informado';
    final entregador = widget.data['entregador'] == '-' ? 'Sem entregador' : (widget.data['entregador'] ?? 'Sem entregador');
    final temObservacao = (widget.data['observacao_interna']?.toString() ?? '').isNotEmpty;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovering ? color.withOpacity(0.4) : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // SEÇÃO 1: ID + Tipo (Compacto)
                    _buildIdSection(tipoEntrega),
                    const SizedBox(width: 16),
                    
                    // SEÇÃO 2: Cliente + Localização
                    Expanded(
                      flex: 3,
                      child: _buildClienteSection(cliente, bairro),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // SEÇÃO 3: Agendamento + Pagamento
                    Expanded(
                      flex: 2,
                      child: _buildInfoSection(slot, pagamento),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // SEÇÃO 4: Entregador + CD
                    Expanded(
                      flex: 2,
                      child: _buildEntregadorSection(entregador),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // SEÇÃO 5: Status + Ações
                    _buildStatusSection(status, color, temObservacao),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SEÇÃO 1: ID + Tipo
  Widget _buildIdSection(String tipoEntrega) {
    final isDelivery = tipoEntrega == 'delivery';
    final tipoColor = isDelivery ? const Color(0xFF2196F3) : const Color(0xFFFF9800);
    
    return Container(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '#${widget.data['id']}',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tipoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tipoColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDelivery ? Icons.delivery_dining_rounded : Icons.store_rounded,
                  size: 12,
                  color: tipoColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isDelivery ? 'Entrega' : 'Retirada',
                  style: AppTypography.caption.copyWith(
                    color: tipoColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SEÇÃO 2: Cliente + Localização
  Widget _buildClienteSection(Map<String, dynamic>? cliente, String bairro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cliente?['nome'] ?? 'Cliente',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bairro,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SEÇÃO 3: Agendamento + Pagamento
  Widget _buildInfoSection(String slot, Map<String, dynamic>? pagamento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(Icons.schedule_rounded, size: 12, color: const Color(0xFFFF9800)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                slot,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              widget.controller.getPaymentIcon(pagamento?['metodo_principal']),
              size: 13,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pagamento?['metodo_principal'] ?? 'Pagamento',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SEÇÃO 4: Entregador + CD
  Widget _buildEntregadorSection(String entregador) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEntregadorQuickAction(entregador),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warehouse_rounded, size: 11, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                widget.data['cd'] ?? 'CD',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SEÇÃO 5: Status + Badges
  Widget _buildStatusSection(String status, Color color, bool temObservacao) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildStatusQuickAction(status, color),
          if (temObservacao) ...[
            const SizedBox(height: 6),
            Tooltip(
              message: 'Pedido com observação interna',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: const Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Observação',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Quick Action: Status
  Widget _buildStatusQuickAction(String status, Color color) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.controller.getStatusIcon(status), size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              status,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 15, color: Colors.white.withOpacity(0.8)),
          ],
        ),
      ),
      itemBuilder: (context) => widget.controller.statusList.map((s) {
        final isSelected = s == status;
        final statusColor = widget.controller.getStatusColor(s);
        
        return PopupMenuItem<String>(
          value: s,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.controller.getStatusIcon(s),
                    size: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? statusColor : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: statusColor),
              ],
            ),
          ),
        );
      }).toList(),
      onSelected: (novoStatus) async {
        final sucesso = await widget.controller.atualizarStatus(
          pedidoId: widget.pedidoId,
          id: widget.data['id'],
          cd: widget.data['cd'],
          novoStatus: novoStatus,
        );

        if (sucesso) {
          widget.onAtualizado();
          if (mounted) {
            AppSnackbar.show(
              context,
              message: '✓ Status: $novoStatus',
              type: AppSnackbarType.success,
            );
          }
        } else {
          if (mounted) {
            AppSnackbar.show(
              context,
              message: 'Erro ao atualizar status',
              type: AppSnackbarType.error,
            );
          }
        }
      },
    );
  }

  // Quick Action: Entregador
  Widget _buildEntregadorQuickAction(String entregadorAtual) {
    if (widget.controller.loadingEntregadores) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Text('Carregando...', style: AppTypography.caption.copyWith(fontSize: 11)),
        ],
      );
    }

    return PopupMenuButton<String?>(
      offset: const Offset(0, 35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.motorcycle_rounded, size: 13, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                entregadorAtual,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text('Sem entregador', style: AppTypography.bodySmall),
            ],
          ),
        ),
        ...widget.controller.entregadores.map((nome) {
          final isSelected = nome == entregadorAtual;
          
          return PopupMenuItem<String?>(
            value: nome,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(isSelected ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.motorcycle_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nome,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
      ],
      onSelected: (novoEntregador) async {
        final sucesso = await widget.controller.atualizarEntregador(
          pedidoId: widget.pedidoId,
          id: widget.data['id'],
          cd: widget.data['cd'],
          status: widget.data['status'],
          entregador: novoEntregador,
        );

        if (sucesso) {
          widget.onAtualizado();
          if (mounted) {
            AppSnackbar.show(
              context,
              message: '✓ Entregador atualizado!',
              type: AppSnackbarType.success,
            );
          }
        } else {
          if (mounted) {
            AppSnackbar.show(
              context,
              message: 'Erro ao atualizar entregador',
              type: AppSnackbarType.error,
            );
          }
        }
      },
    );
  }
}