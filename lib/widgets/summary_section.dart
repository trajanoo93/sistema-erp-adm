// lib/widgets/summary_section.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../globals.dart';
import '../models/pedido_state.dart';

class SummarySection extends StatelessWidget {
  final double totalOriginal;
  final bool isCouponValid;
  final String couponCode;
  final double discountAmount;
  final double totalWithDiscount;
  final bool isLoading;
  final Future<void> Function() onCreateOrder;
  final PedidoState pedido;
  final String? paymentInstructions;
  final String? resultMessage;

  const SummarySection({
    Key? key,
    required this.totalOriginal,
    required this.isCouponValid,
    required this.couponCode,
    required this.discountAmount,
    required this.totalWithDiscount,
    required this.isLoading,
    required this.onCreateOrder,
    required this.pedido,
    this.paymentInstructions,
    this.resultMessage,
  }) : super(key: key);

  Future<void> _log(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final unidade = (currentUser?.unidade ?? 'Desconhecida').replaceAll(' ', '_').toLowerCase();
      final appDir = Directory('${dir.path}/ERPUnificado/$unidade');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final file = File('${appDir.path}/app_logs.txt');
      await file.writeAsString('[${DateTime.now()}] [Resumo] $message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Falha ao logar resumo: $e');
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String? text) async {
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma instrução para copiar.'), backgroundColor: Colors.redAccent),
      );
      await _log('Erro: texto vazio em _copyToClipboard');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado para a área de transferência!'), backgroundColor: Colors.green),
    );
    await _log('Texto copiado: $text');
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF28C38);
    final successColor = Colors.green.shade600;
    final unidade = currentUser?.unidade ?? 'CD';

    String? paymentText;
    bool isPix = false;
    if (paymentInstructions != null) {
      try {
        final data = jsonDecode(paymentInstructions!);
        paymentText = data['type'] == 'pix' ? data['text'] : data['url'];
        isPix = data['type'] == 'pix';
        _log('Instruções de pagamento: type=${data['type']}, value=$paymentText');
      } catch (e) {
        paymentText = paymentInstructions;
        isPix = !paymentInstructions!.contains('stripe');
        _log('Erro ao parsear paymentInstructions: $e');
      }
    }

    // AUTO-SELEÇÃO: Se não houver método selecionado, pega o primeiro
    if (pedido.selectedPaymentMethod.isEmpty && pedido.availablePaymentMethods.isNotEmpty) {
      pedido.selectedPaymentMethod = pedido.availablePaymentMethods.first['title'] ?? '';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.summarize, color: primaryColor),
            title: Text(
              'Resumo do Pedido - $unidade',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),

          _buildRow(
            icon: Icons.location_on,
            label: 'Loja Selecionada',
            value: pedido.storeFinal.isNotEmpty ? pedido.storeFinal : 'Aguardando',
            valueStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          _buildRow(label: 'Total dos Produtos', value: 'R\$ ${totalOriginal.toStringAsFixed(2)}'),
          _buildRow(label: 'Custo de Envio', value: 'R\$ ${pedido.shippingCost.toStringAsFixed(2)}'),

          if (isCouponValid) ...[
            const SizedBox(height: 8),
            _buildRow(
              icon: Icons.discount,
              label: 'Desconto ($couponCode)',
              value: '- R\$ ${discountAmount.toStringAsFixed(2)}',
              valueStyle: GoogleFonts.poppins(fontSize: 16, color: successColor, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),

          _buildRow(
            label: 'Total com Desconto',
            value: 'R\$ ${totalWithDiscount.toStringAsFixed(2)}',
            valueStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // MÉTODO DE PAGAMENTO COM AUTO-SELEÇÃO
          DropdownButtonFormField<String>(
            value: pedido.availablePaymentMethods.isNotEmpty
                ? pedido.selectedPaymentMethod.isNotEmpty
                    ? pedido.selectedPaymentMethod
                    : pedido.availablePaymentMethods.first['title']
                : null,
            decoration: _inputDecoration('Método de Pagamento', Icons.payment),
            items: pedido.availablePaymentMethods
                .map((m) => DropdownMenuItem(
                      value: m['title'] ?? '',
                      child: Text(m['title'] ?? ''),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                pedido.selectedPaymentMethod = v;
                pedido.notifyListeners();
                _log('Método de pagamento: $v');
              }
            },
            validator: (v) => v == null ? 'Selecione o pagamento' : null,
            hint: Text('Selecione data/horário primeiro', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading || pedido.selectedPaymentMethod.isEmpty ? null : onCreateOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Criar Pedido', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),

          if (resultMessage != null) ...[
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: resultMessage!.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: resultMessage!.contains('Erro') ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: resultMessage!.contains('Erro') ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(resultMessage!.contains('Erro') ? Icons.error : Icons.check_circle,
                        color: resultMessage!.contains('Erro') ? Colors.redAccent : successColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        resultMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: resultMessage!.contains('Erro') ? Colors.redAccent : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (paymentInstructions != null && paymentText != null && paymentText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isPix ? Icons.qr_code : Icons.credit_card, color: successColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          isPix ? 'Pagamento via Pix' : 'Pagamento via Cartão',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: successColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPix ? 'Código Pix:' : 'Link de Pagamento:',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            paymentText!,
                            style: GoogleFonts.poppins(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.copy, size: 20, color: primaryColor),
                          onPressed: () => _copyToClipboard(context, paymentText),
                          tooltip: isPix ? 'Copiar Pix' : 'Copiar Link',
                        ),
                      ],
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

  Widget _buildRow({
    IconData? icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, color: const Color(0xFFF28C38), size: 20), const SizedBox(width: 8)],
            Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: valueStyle ?? GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFF28C38).withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFF28C38).withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF28C38), width: 2)),
      prefixIcon: Icon(icon, color: const Color(0xFFF28C38)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}