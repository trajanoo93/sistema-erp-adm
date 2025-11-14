// lib/pages/pedidos/controllers/pedidos_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String GOOGLE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbwZuFyCgoLU_oTUc98ayUDFnR4aGwIYTzDGWOoJT99elnUdN6sp1s_tm5r7gaQol1lb/exec';

class PedidosController extends ChangeNotifier {
  // ========================================
  // PROPRIEDADES
  // ========================================
  String cdFiltro = 'CD Central';
  DateTime? dataInicial;
  DateTime? dataFinal;
  String busca = '';
  Set<String> statusFiltros = {};
  Set<String> pagamentoFiltros = {}; // NOVO: Filtro de pagamento
  
  final cds = ['CD Central', 'CD Sion', 'CD Barreiro', 'CD Lagoa Santa', 'Todos'];
  final statusList = [
    'Pendente',
    'Processando',
    'Registrado',
    'Agendado',
    'Saiu pra Entrega',
    'Concluído',
    'Cancelado',
    'Publi',
    'Retirado'
  ];
  final pagamentosList = ['Pix', 'Cartão', 'Crédito Site', 'V.A.']; // NOVO

  List<String> entregadores = [];
  bool loadingEntregadores = true;

  // ========================================
  // INICIALIZAÇÃO
  // ========================================
  PedidosController() {
    final hoje = DateTime.now();
    dataInicial = DateTime(hoje.year, hoje.month, hoje.day);
    dataFinal = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    carregarEntregadores();
  }

  // ========================================
  // FILTROS
  // ========================================
  void setCdFiltro(String cd) {
    cdFiltro = cd;
    notifyListeners();
  }

  void setDataInicial(DateTime? data) {
    dataInicial = data;
    notifyListeners();
  }

  void setDataFinal(DateTime? data) {
    dataFinal = data;
    notifyListeners();
  }

  void setBusca(String texto) {
    busca = texto.toLowerCase();
    notifyListeners();
  }

  void toggleStatusFiltro(String status) {
    if (statusFiltros.contains(status)) {
      statusFiltros.remove(status);
    } else {
      statusFiltros.add(status);
    }
    notifyListeners();
  }

  void togglePagamentoFiltro(String pagamento) {
    if (pagamentoFiltros.contains(pagamento)) {
      pagamentoFiltros.remove(pagamento);
    } else {
      pagamentoFiltros.add(pagamento);
    }
    notifyListeners();
  }

  void limparFiltros() {
    busca = '';
    statusFiltros.clear();
    pagamentoFiltros.clear();
    notifyListeners();
  }

  // ========================================
  // QUERY FIRESTORE
  // ========================================
  Query buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('is_ativo', isEqualTo: true);

    if (cdFiltro == 'Todos') {
      // sem filtro
    } else if (cdFiltro == 'CD Central') {
      query = query.where('cd', whereIn: ['CD Central', '']);
    } else {
      query = query.where('cd', isEqualTo: cdFiltro);
    }

    if (dataInicial != null || dataFinal != null) {
      query = query.orderBy('agendamento.data', descending: true);
      if (dataInicial != null) {
        query = query.where('agendamento.data', isGreaterThanOrEqualTo: dataInicial);
      }
      if (dataFinal != null) {
        query = query.where('agendamento.data', isLessThanOrEqualTo: dataFinal);
      }
    }

    query = query.orderBy('created_at', descending: true);
    return query;
  }

  // ========================================
  // FILTRO DE PEDIDOS (CLIENTE)
  // ========================================
  List<QueryDocumentSnapshot> filtrarPedidos(List<QueryDocumentSnapshot> docs) {
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] == '-' ? 'Processando' : (data['status'] ?? 'Processando');
      final cliente = data['cliente'] as Map<String, dynamic>?;
      final endereco = data['endereco'] as Map<String, dynamic>?;
      final pagamento = data['pagamento'] as Map<String, dynamic>?;
      final id = data['id']?.toString() ?? '';
      final nome = cliente?['nome']?.toString().toLowerCase() ?? '';
      final bairro = endereco?['bairro']?.toString().toLowerCase() ?? '';
      final metodoPagamento = pagamento?['metodo_principal']?.toString() ?? '';

      final matchesBusca = busca.isEmpty || id.contains(busca) || nome.contains(busca) || bairro.contains(busca);
      final matchesStatus = statusFiltros.isEmpty || statusFiltros.contains(status);
      final matchesPagamento = pagamentoFiltros.isEmpty || pagamentoFiltros.contains(metodoPagamento);

      return matchesBusca && matchesStatus && matchesPagamento;
    }).toList();

    // ORDENAÇÃO
    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final createdA = (dataA['created_at'] as Timestamp?)?.toDate() ?? DateTime(0);
      final createdB = (dataB['created_at'] as Timestamp?)?.toDate() ?? DateTime(0);
      final compareCreated = createdB.compareTo(createdA);
      if (compareCreated != 0) return compareCreated;

      final slotA = (dataA['agendamento']?['janela_texto'] ?? '').toString();
      final slotB = (dataB['agendamento']?['janela_texto'] ?? '').toString();
      final horaA = extrairHoraInicial(slotA);
      final horaB = extrairHoraInicial(slotB);

      if (horaA == null && horaB == null) return 0;
      if (horaA == null) return 1;
      if (horaB == null) return -1;
      return horaA.compareTo(horaB);
    });

    return filtered;
  }

  DateTime? extrairHoraInicial(String slot) {
    final match = RegExp(r'(\d{2}:\d{2})').firstMatch(slot);
    if (match == null) return null;

    final hora = match.group(1)!;
    try {
      final hoje = DateTime.now();
      final partes = hora.split(':');
      return DateTime(hoje.year, hoje.month, hoje.day, int.parse(partes[0]), int.parse(partes[1]));
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // ENTREGADORES
  // ========================================
  Future<void> carregarEntregadores() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('entregadores').get();
      entregadores = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['nome'] ?? data['Nome'] ?? data['NOME'] ?? 'Sem nome') as String;
      }).toList();
      loadingEntregadores = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar entregadores: $e');
      loadingEntregadores = false;
      notifyListeners();
    }
  }

  // ========================================
  // ATUALIZAÇÕES FIRESTORE + SHEETS
  // ========================================
  Future<bool> atualizarEntregador({
    required String pedidoId,
    required String id,
    required String cd,
    required String status,
    required String? entregador,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'entregador': entregador ?? '-',
        'updated_at': FieldValue.serverTimestamp(),
      });

      await sincronizarComSheets(
        id: id,
        cd: cd,
        status: status,
        entregador: entregador ?? '-',
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar entregador: $e');
      return false;
    }
  }

  Future<bool> atualizarStatus({
    required String pedidoId,
    required String id,
    required String cd,
    required String novoStatus,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'status': novoStatus == 'Processando' ? '-' : novoStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await sincronizarComSheets(
        id: id,
        cd: cd,
        status: novoStatus,
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
      return false;
    }
  }

  Future<bool> atualizarPagamento({
    required String pedidoId,
    required String id,
    required String cd,
    required String status,
    required List<Map<String, dynamic>> formas,
    required double valorTotal,
    required double taxaEntrega,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'pagamento.formas': formas,
        'pagamento.valor_total': valorTotal,
        'pagamento.taxa_entrega': taxaEntrega,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await sincronizarComSheets(
        id: id,
        cd: cd,
        status: status,
        formasPagamento: formas,
        valorTotal: valorTotal,
        taxaEntrega: taxaEntrega,
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar pagamento: $e');
      return false;
    }
  }

  // NOVO: Atualizar observação
  Future<bool> atualizarObservacao({
    required String pedidoId,
    required String observacao,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'observacao_interna': observacao,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar observação: $e');
      return false;
    }
  }

  // ========================================
  // SINCRONIZAÇÃO GOOGLE SHEETS
  // ========================================
  Future<void> sincronizarComSheets({
    required String id,
    required String cd,
    required String status,
    String? entregador,
    List<Map<String, dynamic>>? formasPagamento,
    double? valorTotal,
    double? taxaEntrega,
  }) async {
    try {
      final payload = {
        'action': 'UpdatePedido',
        'id': id,
        'cd': cd,
        'status': status,
      };

      if (entregador != null) {
        payload['entregador'] = entregador;
      }

      if (formasPagamento != null && formasPagamento.isNotEmpty) {
        final formasTexto = formasPagamento.map((f) => f['tipo']).join(' + ');
        payload['pagamento'] = formasTexto;
      }

      if (valorTotal != null) {
        payload['valor_total'] = valorTotal.toString();
      }

      if (taxaEntrega != null) {
        payload['taxa_entrega'] = taxaEntrega.toString();
      }

      final response = await http.get(
        Uri.parse(GOOGLE_SCRIPT_URL).replace(queryParameters: payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] != 'success') {
          debugPrint('Erro ao sincronizar com Sheets: ${result['message']}');
        }
      } else {
        debugPrint('Erro HTTP ao sincronizar com Sheets: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar com Sheets: $e');
    }
  }

  // ========================================
  // HELPERS
  // ========================================
  Color getStatusColor(String status) {
    return switch (status) {
      'Pendente' => const Color(0xFFFF9800),
      'Processando' => const Color(0xFF2196F3),
      'Registrado' => const Color(0xFF9C27B0),
      'Agendado' => const Color(0xFF3F51B5),
      'Saiu pra Entrega' => const Color(0xFF4CAF50),
      'Concluído' => const Color(0xFF009688),
      'Cancelado' => const Color(0xFFF44336),
      'Publi' => const Color(0xFF00BCD4),
      'Retirado' => const Color(0xFF795548),
      _ => const Color(0xFF9E9E9E),
    };
  }

  IconData getStatusIcon(String status) {
    return switch (status) {
      'Pendente' => Icons.hourglass_top_rounded,
      'Processando' => Icons.autorenew_rounded,
      'Registrado' => Icons.assignment_rounded,
      'Agendado' => Icons.schedule_rounded,
      'Saiu pra Entrega' => Icons.local_shipping_rounded,
      'Concluído' => Icons.check_circle_rounded,
      'Cancelado' => Icons.cancel_rounded,
      'Publi' => Icons.public_rounded,
      'Retirado' => Icons.store_rounded,
      _ => Icons.help_rounded,
    };
  }

  IconData getPaymentIcon(String? metodo) {
    return switch (metodo) {
      'Pix' => Icons.qr_code_rounded,
      'Cartão' => Icons.credit_card_rounded,
      'Crédito Site' => Icons.web_rounded,
      'V.A.' => Icons.local_atm_rounded,
      _ => Icons.payment_rounded,
    };
  }
}