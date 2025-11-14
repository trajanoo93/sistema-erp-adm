// lib/pages/pedidos/modals/detalhes_pedido_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../design_system.dart';
import '../controllers/pedidos_controller.dart';
import '../../../services/impressao_service.dart';
import 'pagamento_dialog.dart';

class DetalhesPedidoModal extends StatefulWidget {
  final Map<String, dynamic> data;
  final String pedidoId;
  final PedidosController controller;
  final VoidCallback onAtualizado;

  const DetalhesPedidoModal({
    Key? key,
    required this.data,
    required this.pedidoId,
    required this.controller,
    required this.onAtualizado,
  }) : super(key: key);

  @override
  State<DetalhesPedidoModal> createState() => _DetalhesPedidoModalState();
}

class _DetalhesPedidoModalState extends State<DetalhesPedidoModal> {
  late List<Map<String, dynamic>> formas;
  String? entregadorSelecionado;
  String? statusSelecionado;
  late double valorTotal;
  late double taxa;
  late TextEditingController _observacaoController;
  bool _editandoObservacao = false;

  @override
  void initState() {
    super.initState();
    
    final statusAtual = widget.data['status'] == '-' ? 'Processando' : (widget.data['status'] ?? 'Processando');
    statusSelecionado = statusAtual;
    
    final pagamento = widget.data['pagamento'] as Map<String, dynamic>?;
    formas = (pagamento?['formas'] as List?)?.cast<Map<String, dynamic>>() ?? [
      {'tipo': pagamento?['metodo_principal'] ?? 'Cartão', 'valor': pagamento?['valor_total'] ?? 0.0}
    ];

    valorTotal = (pagamento?['valor_total'] as num?)?.toDouble() ?? 0.0;
    taxa = (pagamento?['taxa_entrega'] as num?)?.toDouble() ?? 0.0;
    
    final entregadorAtual = widget.data['entregador'];
    entregadorSelecionado = (entregadorAtual == '-' || entregadorAtual == null) ? null : entregadorAtual;

    // NOVO: Controller de observação
    _observacaoController = TextEditingController(
      text: widget.data['observacao_interna']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] == '-' ? 'Processando' : (widget.data['status'] ?? 'Processando');
    final color = widget.controller.getStatusColor(status);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedido #${widget.data['id']}', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(widget.controller.getStatusIcon(status), size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // NOVO: Botão de Impressão
                  AppIconButton(
                    icon: Icons.print_rounded,
                    tooltip: 'Imprimir Pedido',
                    size: 20,
                    onPressed: _imprimirPedido,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            
            // Conteúdo
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildClienteSection(),
                  const SizedBox(height: 16),
                  _buildPedidoSection(),
                  const SizedBox(height: 16),
                  _buildItensSection(),
                  const SizedBox(height: 16),
                  _buildPagamentoSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSection() {
    return _buildSection(
      title: 'Informações do Cliente',
      icon: Icons.person_rounded,
      children: [
        _infoRow(Icons.badge_rounded, 'Nome', widget.data['cliente']?['nome']),
        _infoRow(Icons.phone_rounded, 'Telefone', widget.data['cliente']?['telefone']),
        _infoRow(Icons.location_on_rounded, 'Bairro', widget.data['endereco']?['bairro']),
        _infoRow(Icons.home_rounded, 'Endereço', widget.data['endereco']?['logradouro']),
      ],
    );
  }

  Widget _buildPedidoSection() {
    return _buildSection(
      title: 'Informações do Pedido',
      icon: Icons.shopping_bag_rounded,
      children: [
        _infoRow(Icons.warehouse_rounded, 'CD', widget.data['cd']),
        // NOVO: Campo Origem
        _infoRow(Icons.source_rounded, 'Origem', widget.data['loja_origem'] ?? 'Não informado'),
        _buildEntregadorRow(),
        _buildStatusRow(),
        if (widget.data['agendamento']?['is_agendado'] == true)
          _infoRow(Icons.schedule_rounded, 'Agendamento', widget.data['agendamento']?['janela_texto']),
      ],
    );
  }

  Widget _buildItensSection() {
    return _buildSection(
      title: 'Itens do Pedido',
      icon: Icons.list_alt_rounded,
      children: [
        ...(widget.data['itens'] as List).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item['quantidade']}x',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['nome'] ?? 'Item',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    // NOVO: Mostra variações se houver
                    if (item['variacoes'] != null && (item['variacoes'] as List).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: (item['variacoes'] as List).map((variacao) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                variacao.toString(),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    // Mostra valor se disponível
                    if (item['valor_unitario'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'R\$ ${(item['valor_unitario'] as num).toStringAsFixed(2)}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPagamentoSection() {
    final totalPago = formas.fold(0.0, (sum, f) => sum + (f['valor'] as num).toDouble());
    final temDivergencia = (totalPago - valorTotal).abs() >= 0.01;
    final divergenciaColor = temDivergencia ? const Color(0xFFFF9800) : AppColors.success; // LARANJA em vez de vermelho

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payment_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Pagamento', style: AppTypography.label),
                ],
              ),
              AppIconButton(
                icon: Icons.edit_rounded,
                tooltip: 'Editar Pagamento',
                size: 16,
                onPressed: _editarPagamento,
              ),
            ],
          ),
          const Divider(height: 20),
          ...formas.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_getIconForma(f['tipo']), size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f['tipo'],
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      'R\$ ${(f['valor'] as num).toStringAsFixed(2)}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Taxa de Entrega')),
              Text(
                'R\$ ${taxa.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                temDivergencia ? Icons.warning_rounded : Icons.paid_rounded,
                size: 18,
                color: divergenciaColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  temDivergencia ? 'TOTAL (com divergência)' : 'TOTAL',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: divergenciaColor,
                  ),
                ),
              ),
              Text(
                'R\$ ${valorTotal.toStringAsFixed(2)}',
                style: AppTypography.cardTitle.copyWith(
                  color: divergenciaColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (temDivergencia)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: divergenciaColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: divergenciaColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: divergenciaColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Valor pago: R\$ ${totalPago.toStringAsFixed(2)} • Diferença pode ser ajustada por peso/variação',
                        style: AppTypography.caption.copyWith(
                          color: divergenciaColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // NOVO: Seção de observação
  Widget _buildObservacaoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.note_rounded, color: const Color(0xFFFF9800), size: 18),
                  const SizedBox(width: 8),
                  Text('Observação Interna', style: AppTypography.label),
                ],
              ),
              if (!_editandoObservacao)
                AppIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'Editar Observação',
                  size: 16,
                  onPressed: () => setState(() => _editandoObservacao = true),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_editandoObservacao)
            Column(
              children: [
                TextField(
                  controller: _observacaoController,
                  maxLines: 3,
                  style: AppTypography.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Ex: Cliente alterou forma de pagamento para Pix...',
                    hintStyle: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _observacaoController.text = widget.data['observacao_interna']?.toString() ?? '';
                        setState(() => _editandoObservacao = false);
                      },
                      child: Text('Cancelar', style: AppTypography.bodySmall),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _salvarObservacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Salvar', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              _observacaoController.text.isEmpty
                  ? 'Nenhuma observação registrada'
                  : _observacaoController.text,
              style: AppTypography.bodySmall.copyWith(
                color: _observacaoController.text.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                fontStyle: _observacaoController.text.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _salvarObservacao() async {
    final sucesso = await widget.controller.atualizarObservacao(
      pedidoId: widget.pedidoId,
      observacao: _observacaoController.text,
    );

    if (sucesso) {
      setState(() => _editandoObservacao = false);
      widget.onAtualizado();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Observação salva com sucesso!',
          type: AppSnackbarType.success,
        );
      }
    } else {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Erro ao salvar observação',
          type: AppSnackbarType.error,
        );
      }
    }
  }

  // NOVO: Função de impressão
  Future<void> _imprimirPedido() async {
    // Mostra loading
    AppSnackbar.show(
      context,
      message: '🖨️ Enviando para impressora...',
      type: AppSnackbarType.info,
    );

    final sucesso = await ImpressaoService.imprimirPedido(context, widget.data);

    if (mounted) {
      if (sucesso) {
        AppSnackbar.show(
          context,
          message: '✓ Pedido enviado para impressão!',
          type: AppSnackbarType.success,
        );
      } else {
        AppSnackbar.show(
          context,
          message: 'Erro ao imprimir pedido',
          type: AppSnackbarType.error,
        );
      }
    }
  }

  Widget _buildEntregadorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.motorcycle_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Entregador:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: widget.controller.loadingEntregadores
                ? Text('Carregando...', style: AppTypography.bodySmall)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOpacity8,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryOpacity25),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: entregadorSelecionado,
                        isExpanded: true,
                        isDense: true,
                        hint: Text('Selecione um entregador', style: AppTypography.bodySmall),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Sem entregador')),
                          ...widget.controller.entregadores.map((nome) => DropdownMenuItem<String?>(
                                value: nome,
                                child: Text(nome, style: AppTypography.bodySmall),
                              )),
                        ],
                        onChanged: (novoEntregador) async {
                          setState(() => entregadorSelecionado = novoEntregador);

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
                                message: 'Entregador atualizado!',
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
                        icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sync_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Status:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryOpacity8,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryOpacity25),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: statusSelecionado,
                  isExpanded: true,
                  isDense: true,
                  items: widget.controller.statusList.map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(widget.controller.getStatusIcon(s), size: 16, color: widget.controller.getStatusColor(s)),
                        const SizedBox(width: 6),
                        Text(s, style: AppTypography.bodySmall),
                      ],
                    ),
                  )).toList(),
                  onChanged: (novoStatus) async {
                    if (novoStatus == null) return;
                    setState(() => statusSelecionado = novoStatus);

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
                          message: 'Status atualizado para: $novoStatus',
                          type: AppSnackbarType.success,
                        );
                      }
                    } else {
                      setState(() => statusSelecionado = widget.data['status'] == '-' ? 'Processando' : widget.data['status']);
                      if (mounted) {
                        AppSnackbar.show(
                          context,
                          message: 'Erro ao atualizar status',
                          type: AppSnackbarType.error,
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editarPagamento() {
    showDialog(
      context: context,
      builder: (_) => PagamentoDialog(
        formasIniciais: List.from(formas),
        valorTotalInicial: valorTotal,
        taxaInicial: taxa,
        observacaoInicial: widget.data['observacao_interna']?.toString(), // NOVO
        onSalvar: (novasFormas, novoTotal, novaTaxa, novaObservacao) async {
          final sucesso = await widget.controller.atualizarPagamento(
            pedidoId: widget.pedidoId,
            id: widget.data['id'],
            cd: widget.data['cd'],
            status: widget.data['status'],
            formas: novasFormas,
            valorTotal: novoTotal,
            taxaEntrega: novaTaxa,
          );

          // NOVO: Atualiza observação separadamente
          if (sucesso && novaObservacao != null) {
            await widget.controller.atualizarObservacao(
              pedidoId: widget.pedidoId,
              observacao: novaObservacao,
            );
          }

          if (sucesso) {
            setState(() {
              formas = novasFormas;
              valorTotal = novoTotal;
              taxa = novaTaxa;
            });
            widget.onAtualizado();
            Navigator.pop(context);
            AppSnackbar.show(
              context,
              message: 'Pagamento atualizado!',
              type: AppSnackbarType.success,
            );
          } else {
            AppSnackbar.show(
              context,
              message: 'Erro ao atualizar pagamento',
              type: AppSnackbarType.error,
            );
          }
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForma(String tipo) {
    return widget.controller.getPaymentIcon(tipo);
  }
}