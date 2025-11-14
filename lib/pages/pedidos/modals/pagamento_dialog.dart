// lib/pages/pedidos/modals/pagamento_dialog.dart
import 'package:flutter/material.dart';
import '../../../design_system.dart';

class PagamentoDialog extends StatefulWidget {
  final List<Map<String, dynamic>> formasIniciais;
  final double valorTotalInicial;
  final double taxaInicial;
  final String? observacaoInicial; // NOVO
  final Function(List<Map<String, dynamic>>, double, double, String?) onSalvar; // ATUALIZADO

  const PagamentoDialog({
    Key? key,
    required this.formasIniciais,
    required this.valorTotalInicial,
    required this.taxaInicial,
    this.observacaoInicial, // NOVO
    required this.onSalvar,
  }) : super(key: key);

  @override
  State<PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<PagamentoDialog> {
  late List<Map<String, dynamic>> formas;
  final List<TextEditingController> _controllers = [];
  late TextEditingController _taxaController;
  late TextEditingController _totalController;
  late TextEditingController _observacaoController; // NOVO

  @override
  void initState() {
    super.initState();
    formas = widget.formasIniciais.map((f) => Map<String, dynamic>.from(f)).toList();
    
    for (var forma in formas) {
      final controller = TextEditingController(text: forma['valor'].toString());
      controller.addListener(() {
        final valor = double.tryParse(controller.text) ?? 0.0;
        forma['valor'] = valor;
        setState(() {});
      });
      _controllers.add(controller);
    }

    _taxaController = TextEditingController(text: widget.taxaInicial.toStringAsFixed(2));
    _totalController = TextEditingController(text: widget.valorTotalInicial.toStringAsFixed(2));
    _observacaoController = TextEditingController(text: widget.observacaoInicial ?? ''); // NOVO
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _taxaController.dispose();
    _totalController.dispose();
    _observacaoController.dispose(); // NOVO
    super.dispose();
  }

  double get totalPago => formas.fold(0.0, (sum, f) => sum + (f['valor'] as num).toDouble());
  double get valorTotal => double.tryParse(_totalController.text) ?? 0.0;
  double get taxa => double.tryParse(_taxaController.text) ?? 0.0;
  
  // MUDANÇA: Agora aceita pequenas divergências (produtos pesados)
  bool get temDivergencia => (totalPago - valorTotal).abs() >= 0.01;
  bool get divergenciaGrande => (totalPago - valorTotal).abs() >= 10.0; // >R$10 de diferença
  
  Color get statusColor {
    if (!temDivergencia) return AppColors.success;
    if (divergenciaGrande) return AppColors.error;
    return const Color(0xFFFF9800); // Laranja para divergências pequenas
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOpacity12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Editar Pagamento', style: AppTypography.cardTitle)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Formas de Pagamento
            Text('Formas de Pagamento', style: AppTypography.label),
            const SizedBox(height: 12),
            ...formas.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: DropdownButton<String>(
                            value: f['tipo'],
                            items: ['Cartão', 'Pix', 'Crédito Site', 'V.A.']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.bodySmall)))
                                .toList(),
                            onChanged: (v) => setState(() => f['tipo'] = v),
                            underline: const SizedBox.shrink(),
                            isExpanded: true,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _controllers[i],
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodySmall,
                          decoration: InputDecoration(
                            prefixText: 'R\$ ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      if (formas.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                          onPressed: () {
                            setState(() {
                              _controllers[i].dispose();
                              _controllers.removeAt(i);
                              formas.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                ),
              );
            }),
            AppButton(
              label: 'Adicionar Forma de Pagamento',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outline,
              fullWidth: true,
              size: AppButtonSize.small,
              onPressed: () {
                setState(() {
                  formas.add({'tipo': 'Pix', 'valor': 0.0});
                  final controller = TextEditingController(text: '0.0');
                  controller.addListener(() {
                    final valor = double.tryParse(controller.text) ?? 0.0;
                    formas.last['valor'] = valor;
                    setState(() {});
                  });
                  _controllers.add(controller);
                });
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            
            // Valores
            Text('Valores', style: AppTypography.label),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Taxa de Entrega',
                    controller: _taxaController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.delivery_dining_rounded,
                    onSuffixTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Valor Total',
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.paid_rounded,
                    onSuffixTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status da validação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total pago', style: AppTypography.caption),
                          Text(
                            'R\$ ${totalPago.toStringAsFixed(2)}',
                            style: AppTypography.label.copyWith(color: statusColor),
                          ),
                        ],
                      ),
                      Icon(
                        temDivergencia
                            ? (divergenciaGrande ? Icons.error : Icons.warning)
                            : Icons.check_circle,
                        color: statusColor,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Valor total', style: AppTypography.caption),
                          Text(
                            'R\$ ${valorTotal.toStringAsFixed(2)}',
                            style: AppTypography.label,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (temDivergencia && !divergenciaGrande)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pequena divergência detectada. Comum em produtos pesados.',
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (divergenciaGrande)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Divergência grande! Verifique os valores antes de salvar.',
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Salvar',
                    onPressed: () => widget.onSalvar(formas, valorTotal, taxa, _observacaoController.text),
                  ),
                ),
              ],
            ),
            
            // NOVO: Campo de Observação (discreto no final)
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.note_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Observação Interna',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacaoController,
              maxLines: 2,
              style: AppTypography.bodySmall,
              decoration: InputDecoration(
                hintText: 'Ex: Cliente alterou forma de pagamento...',
                hintStyle: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.bgPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}