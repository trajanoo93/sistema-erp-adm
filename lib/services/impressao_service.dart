// lib/services/impressao_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImpressaoService {
  // Largura da impressora térmica de 80mm (PosX compatible)
  static const double thermalWidthMM = 80.0;
  static const PdfPageFormat thermalFormat = PdfPageFormat(
    thermalWidthMM * PdfPageFormat.mm,
    double.infinity, // Altura infinita para thermal
    marginAll: 5 * PdfPageFormat.mm,
  );

  /// Imprime pedido na impressora térmica EPSON
  static Future<bool> imprimirPedido(
    BuildContext context,
    Map<String, dynamic> pedidoData,
  ) async {
    try {
      // Gera o PDF
      final pdf = await _gerarPDFPedido(pedidoData);

      // Busca impressora EPSON automaticamente
      final printer = await _buscarImpressoraEpson();

      if (printer != null) {
        // Imprime diretamente na EPSON
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) => pdf.save(),
          format: thermalFormat,
        );
        return true;
      } else {
        // Se não encontrou EPSON, abre dialog de seleção
        await Printing.layoutPdf(
          name: 'Pedido_${pedidoData['id']}.pdf',
          format: thermalFormat,
          onLayout: (format) => pdf.save(),
        );
        return true;
      }
    } catch (e) {
      debugPrint('❌ Erro ao imprimir: $e');
      return false;
    }
  }

  /// Busca automaticamente impressora EPSON no sistema
  static Future<Printer?> _buscarImpressoraEpson() async {
    try {
      final printers = await Printing.listPrinters();
      
      // Procura por impressora EPSON (TM-20, TM-T20, etc)
      final epson = printers.firstWhere(
        (p) => p.name.toUpperCase().contains('EPSON') ||
               p.name.toUpperCase().contains('TM'),
        orElse: () => printers.first, // Fallback para primeira impressora
      );
      
      debugPrint('🖨️ Impressora encontrada: ${epson.name}');
      return epson;
    } catch (e) {
      debugPrint('⚠️ Erro ao buscar impressora: $e');
      return null;
    }
  }

  /// Gera PDF formatado para impressora térmica
  static Future<pw.Document> _gerarPDFPedido(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Dados do pedido
    final cliente = data['cliente'] as Map<String, dynamic>?;
    final endereco = data['endereco'] as Map<String, dynamic>?;
    final pagamento = data['pagamento'] as Map<String, dynamic>?;
    final agendamento = data['agendamento'] as Map<String, dynamic>?;
    final itens = data['itens'] as List? ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: thermalFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO
              _buildHeader(data),
              pw.SizedBox(height: 8),
              _buildDivider(),
              pw.SizedBox(height: 8),

              // CLIENTE
              _buildSection('CLIENTE', [
                _buildLine('Nome', cliente?['nome'] ?? 'N/A'),
                _buildLine('Telefone', cliente?['telefone'] ?? 'N/A'),
              ]),
              pw.SizedBox(height: 8),

              // ENDEREÇO
              _buildSection('ENDEREÇO DE ENTREGA', [
                _buildLine('Logradouro', endereco?['logradouro'] ?? 'N/A'),
                _buildLine('Número', endereco?['numero'] ?? 'N/A'),
                _buildLine('Bairro', endereco?['bairro'] ?? 'N/A'),
                if (endereco?['complemento'] != null && endereco!['complemento'].toString().isNotEmpty)
                  _buildLine('Complemento', endereco['complemento']),
                if (endereco?['referencia'] != null && endereco!['referencia'].toString().isNotEmpty)
                  _buildLine('Referência', endereco['referencia']),
              ]),
              pw.SizedBox(height: 8),

              // AGENDAMENTO
              if (agendamento?['is_agendado'] == true)
                _buildSection('AGENDAMENTO', [
                  _buildLine('Data', _formatarData(agendamento?['data'])),
                  _buildLine('Horário', agendamento?['janela_texto'] ?? 'N/A'),
                ]),
              pw.SizedBox(height: 8),
              _buildDivider(),
              pw.SizedBox(height: 8),

              // ITENS DO PEDIDO
              _buildSection('ITENS DO PEDIDO', []),
              pw.SizedBox(height: 4),
              ...itens.map((item) => _buildItemLine(item)),
              pw.SizedBox(height: 8),
              _buildDivider(),
              pw.SizedBox(height: 8),

              // PAGAMENTO
              _buildSection('PAGAMENTO', [
                ..._buildFormasPagamento(pagamento),
                _buildLine('Taxa de Entrega', 'R\$ ${_formatarValor(pagamento?['taxa_entrega'])}'),
                pw.SizedBox(height: 4),
                _buildLineBold('TOTAL', 'R\$ ${_formatarValor(pagamento?['valor_total'])}'),
              ]),
              pw.SizedBox(height: 8),
              _buildDivider(),
              pw.SizedBox(height: 8),

              // INFORMAÇÕES ADICIONAIS
              _buildSection('INFORMAÇÕES', [
                _buildLine('CD', data['cd'] ?? 'N/A'),
                _buildLine('Entregador', data['entregador'] != '-' ? data['entregador'] : 'Não atribuído'),
                _buildLine('Status', data['status'] == '-' ? 'Processando' : data['status']),
              ]),

              // OBSERVAÇÃO (se houver)
              if (data['observacao_interna'] != null && data['observacao_interna'].toString().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _buildDivider(),
                pw.SizedBox(height: 8),
                _buildSection('OBSERVAÇÃO INTERNA', [
                  pw.Text(
                    data['observacao_interna'],
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                  ),
                ]),
              ],

              pw.SizedBox(height: 12),
              _buildDivider(),
              pw.SizedBox(height: 8),

              // RODAPÉ
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Impresso em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Sistema ERP - Gestão de Pedidos',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20), // Espaço para corte
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ========================================
  // COMPONENTES DO PDF
  // ========================================

  static pw.Widget _buildHeader(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'PEDIDO #${data['id']}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            data['tipo_entrega'] == 'delivery' ? '🚚 ENTREGA' : '🏪 RETIRADA',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      height: 1,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1, style: pw.BorderStyle.dashed),
        ),
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...content,
      ],
    );
  }

  static pw.Widget _buildLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLineBold(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemLine(Map<String, dynamic> item) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 20,
            child: pw.Text(
              '${item['quantidade']}x',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              item['nome'] ?? 'Item',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          if (item['valor_unitario'] != null)
            pw.Text(
              'R\$ ${_formatarValor(item['valor_unitario'])}',
              style: const pw.TextStyle(fontSize: 8),
            ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildFormasPagamento(Map<String, dynamic>? pagamento) {
    final formas = pagamento?['formas'] as List? ?? [];
    
    if (formas.isEmpty) {
      return [
        _buildLine('Método', pagamento?['metodo_principal'] ?? 'N/A'),
      ];
    }

    return formas.map((forma) {
      return _buildLine(
        forma['tipo'],
        'R\$ ${_formatarValor(forma['valor'])}',
      );
    }).toList();
  }

  // ========================================
  // HELPERS
  // ========================================

  static String _formatarData(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  static String _formatarValor(dynamic valor) {
    if (valor == null) return '0,00';
    final v = (valor as num).toDouble();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }
}

