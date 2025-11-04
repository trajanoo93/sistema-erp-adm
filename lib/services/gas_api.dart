// lib/services/gas_api.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/pedido_model.dart';
import '../globals.dart';

/// Modelo do Pedido
class Pedido {
  final String? id;
  final String? data;
  final String? horario;
  final String? bairro;
  final String? nome;
  final String? pagamento;
  final num? subTotal;
  final num? total;
  final String? vendedor;
  final num? taxaEntrega;
  final String? status;
  final String? entregador;
  final String? rua;
  final String? numero;
  final String? cep;
  final String? complemento;
  final String? latitude;
  final String? longitude;
  final String? unidade;
  final String? hifen;
  final String? cidade;
  final DateTime? printedAt;
  final String? tipoEntrega;
  final String? dataAgendamento;
  final String? horarioAgendamento;
  final String? telefone;
  final String? observacao;
  final String? produtos;
  final String? rastreio;
  final String? cupomNome;
  final num? cupomPercentual;
  final num? giftDesconto;

  Pedido({
    this.id, this.data, this.horario, this.bairro, this.nome, this.pagamento,
    this.subTotal, this.total, this.vendedor, this.taxaEntrega, this.status,
    this.entregador, this.rua, this.numero, this.cep, this.complemento,
    this.latitude, this.longitude, this.unidade, this.hifen, this.cidade,
    this.printedAt, this.tipoEntrega, this.dataAgendamento, this.horarioAgendamento,
    this.telefone, this.observacao, this.produtos, this.rastreio,
    this.cupomNome, this.cupomPercentual, this.giftDesconto,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    DateTime? parsePrinted(dynamic v) {
      if (v == null || (v is String && v.trim().isEmpty)) return null;
      try { return DateTime.parse(v); } catch (_) { return null; }
    }

    num? _toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
    }

    return Pedido(
      id: json['id']?.toString(),
      data: json['data']?.toString(),
      horario: json['horario']?.toString(),
      bairro: json['bairro']?.toString(),
      nome: json['nome']?.toString(),
      pagamento: json['pagamento']?.toString(),
      subTotal: _toNum(json['subTotal']),
      total: _toNum(json['total']),
      vendedor: json['vendedor']?.toString(),
      taxaEntrega: _toNum(json['taxa_entrega']),
      status: json['status']?.toString(),
      entregador: json['entregador']?.toString(),
      rua: json['rua']?.toString(),
      numero: json['numero']?.toString(),
      cep: json['cep']?.toString(),
      complemento: json['complemento']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      unidade: json['unidade']?.toString(),
      hifen: json['-']?.toString(),
      cidade: json['cidade']?.toString(),
      printedAt: parsePrinted(json['printed_at']),
      tipoEntrega: json['tipo_entrega']?.toString(),
      dataAgendamento: json['data_agendamento']?.toString(),
      horarioAgendamento: json['horario_agendamento']?.toString(),
      telefone: json['telefone']?.toString(),
      observacao: json['observacao']?.toString(),
      produtos: json['produtos']?.toString(),
      rastreio: json['rastreio']?.toString(),
      cupomNome: json['AG']?.toString(),
      cupomPercentual: _toNum(json['AH']),
      giftDesconto: _toNum(json['AI']),
    );
  }

  bool get estaImpresso => printedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data,
    'horario': horario,
    'bairro': bairro,
    'nome': nome,
    'pagamento': pagamento,
    'subTotal': subTotal,
    'total': total,
    'vendedor': vendedor,
    'taxa_entrega': taxaEntrega,
    'status': status,
    'entregador': entregador,
    'rua': rua,
    'numero': numero,
    'cep': cep,
    'complemento': complemento,
    'latitude': latitude,
    'longitude': longitude,
    'unidade': unidade,
    '-': hifen,
    'cidade': cidade,
    'printed_at': printedAt?.toIso8601String(),
    'tipo_entrega': tipoEntrega,
    'data_agendamento': dataAgendamento,
    'horario_agendamento': horarioAgendamento,
    'telefone': telefone,
    'observacao': observacao,
    'produtos': produtos,
    'rastreio': rastreio,
    'AG': cupomNome,
    'AH': cupomPercentual,
    'AI': giftDesconto,
  };
}

class GasResponseException implements Exception {
  final int? statusCode;
  final String message;
  GasResponseException(this.message, {this.statusCode});
  @override String toString() => 'GasResponseException(${statusCode ?? '??'}): $message';
}

/// Cliente HTTP unificado
class GasApi {
  static http.Client? _client;

  static http.Client get client {
    _client ??= http.Client();
    return _client!;
  }

  static void dispose() {
    _client?.close();
    _client = null;
  }

  /// Leitura de pedidos por CD
  static Future<List<Pedido>> readPedidos({bool onlyUnprinted = false}) async {
    final user = currentUser;
    if (user == null) throw GasResponseException('Usuário não autenticado');

    final params = <String, String>{
      'action': 'ReadCD',
      'unidade': user.unidade,
      if (onlyUnprinted) 'only_unprinted': 'true',
    };

    final uri = Uri.parse(user.baseScriptUrl).replace(queryParameters: params);
    if (kDebugMode) print('[GAS] GET $uri');

    try {
      final resp = await client.get(uri).timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) throw GasResponseException('HTTP ${resp.statusCode}');

      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        return decoded.map((e) => Pedido.fromJson(e)).toList();
      } else {
        throw GasResponseException('Formato inválido: $decoded');
      }
    } on SocketException {
      throw GasResponseException('Sem internet');
    } on TimeoutException {
      throw GasResponseException('Tempo esgotado');
    } catch (e) {
      throw GasResponseException('Erro: $e');
    }
  }

  /// Marca como impresso
  static Future<void> markPrinted(String id) async {
    await _executeAction('MarkPrinted', id);
  }

  /// Desmarca impressão
  static Future<void> unmarkPrinted(String id) async {
    await _executeAction('UnmarkPrinted', id);
  }

  /// Atualiza status
  static Future<void> updateStatus(String id, String status) async {
    final user = currentUser;
    if (user == null) throw GasResponseException('Usuário não autenticado');

    // NORMALIZA O ID (remove .0, espaços, etc.)
    final cleanId = id.replaceAll(RegExp(r'\.0$'), '').trim();

    final uri = Uri.parse(user.baseScriptUrl).replace(
      queryParameters: {
        'action': 'UpdateStatusPedidoCD',  // ← NOVA AÇÃO
        'id': cleanId,
        'status': status,
        'unidade': user.unidade,
      },
    );

    if (kDebugMode) print('[GAS] POST $uri');

    try {
      final resp = await client.get(uri).timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) throw GasResponseException('HTTP ${resp.statusCode}');
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['status'] == 'error') {
        throw GasResponseException(decoded['message'] ?? 'Erro');
      }
    } on SocketException {
      throw GasResponseException('Sem internet');
    } on TimeoutException {
      throw GasResponseException('Tempo esgotado');
    } catch (e) {
      throw GasResponseException('Erro: $e');
    }
  }

  /// Ação genérica (mark/unmark)
  static Future<void> _executeAction(String action, String id) async {
    final user = currentUser;
    if (user == null) throw GasResponseException('Usuário não autenticado');

    final params = {
      'action': action,
      'id': id,
      'unidade': user.unidade,
    };

    final uri = Uri.parse(user.baseScriptUrl).replace(queryParameters: params);
    if (kDebugMode) print('[GAS] POST $uri');

    try {
      final resp = await client.get(uri).timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) throw GasResponseException('HTTP ${resp.statusCode}');
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['status'] == 'error') {
        throw GasResponseException(decoded['message'] ?? 'Erro');
      }
    } on SocketException {
      throw GasResponseException('Sem internet');
    } on TimeoutException {
      throw GasResponseException('Tempo esgotado');
    } catch (e) {
      throw GasResponseException('Erro: $e');
    }
  }
}