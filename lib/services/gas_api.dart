// lib/services/gas_api.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../globals.dart';

/// Modelo do Pedido (campos conforme ReadCD* do Apps Script)
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
    this.id,
    this.data,
    this.horario,
    this.bairro,
    this.nome,
    this.pagamento,
    this.subTotal,
    this.total,
    this.vendedor,
    this.taxaEntrega,
    this.status,
    this.entregador,
    this.rua,
    this.numero,
    this.cep,
    this.complemento,
    this.latitude,
    this.longitude,
    this.unidade,
    this.hifen,
    this.cidade,
    this.printedAt,
    this.tipoEntrega,
    this.dataAgendamento,
    this.horarioAgendamento,
    this.telefone,
    this.observacao,
    this.produtos,
    this.rastreio,
    this.cupomNome,
    this.cupomPercentual,
    this.giftDesconto,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    DateTime? parsePrinted(dynamic v) {
      if (v == null || (v is String && v.trim().isEmpty)) return null;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    num? _toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      final cleaned = v.toString().replaceAll(',', '.');
      return num.tryParse(cleaned);
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

  Map<String, dynamic> toJson() {
    return {
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
}

/// Exceção específica
class GasResponseException implements Exception {
  final int? statusCode;
  final String message;
  GasResponseException(this.message, {this.statusCode});
  @override
  String toString() => 'GasResponseException(${statusCode ?? '??'}): $message';
}

/// Cliente unificado com proteção contra fechamento
class GasApi {
  // Cliente HTTP singleton com recriação automática
  static http.Client get _client {
    if (_internalClient == null || _internalClient.hashCode == 0) {
      _internalClient = http.Client();
      if (kDebugMode) print('[GasApi] Novo http.Client criado');
    }
    return _internalClient!;
  }

  static http.Client? _internalClient;

  /// Garante que o cliente está ativo
  static void _ensureClient() {
    if (_internalClient == null) {
      _internalClient = http.Client();
    }
  }

  /// Lê pedidos da CD do usuário logado
  static Future<List<Pedido>> readPedidos({bool onlyUnprinted = false}) async {
    final user = currentUserGlobal;
    if (user == null) throw GasResponseException('Usuário não autenticado');

    final uri = Uri.parse(user.baseScriptUrl).replace(queryParameters: {
      'action': user.readAction,
      'storeId': user.storeId,
      'unidade': user.unidade,
      'only_unprinted': onlyUnprinted.toString(),
    });

    if (kDebugMode) print('[GAS] GET $uri');

    _ensureClient();

    try {
      final resp = await _client
          .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
          .timeout(const Duration(seconds: 60)); // Aumentado para 60s

      if (resp.statusCode != 200) {
        throw GasResponseException('HTTP ${resp.statusCode}', statusCode: resp.statusCode);
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['status']?.toString().toLowerCase() == 'error') {
        throw GasResponseException(decoded['message'] ?? 'Erro no GAS');
      }

      if (decoded is List) {
        return decoded.map((e) => Pedido.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw GasResponseException('Formato inesperado: $decoded');
      }
    } on SocketException {
      throw GasResponseException('Sem conexão com a internet');
    } on TimeoutException {
      throw GasResponseException('Tempo esgotado (60s). O servidor demorou para responder.');
    } on http.ClientException catch (e) {
      // Recria o cliente se estiver fechado
      if (e.message.contains('Client is already closed')) {
        _internalClient?.close();
        _internalClient = http.Client();
        if (kDebugMode) print('[GasApi] Cliente HTTP recriado após fechamento');
      }
      rethrow;
    } catch (e) {
      throw GasResponseException('Erro inesperado: $e');
    }
  }

  /// Marca como impresso
  static Future<void> markPrinted(String id) async {
    await _postAction(currentUserGlobal!.markPrintedAction, {'id': id});
  }

  /// Desmarca impressão
  static Future<void> unmarkPrinted(String id) async {
    await _postAction(currentUserGlobal!.unmarkPrintedAction, {'id': id});
  }

  /// Atualiza status
  static Future<void> updateStatus(String id, String novoStatus) async {
    await _postAction(currentUserGlobal!.updateStatusAction, {
      'id': id,
      'novoStatus': novoStatus,
    });
  }

  /// Função genérica para ações POST
  static Future<void> _postAction(String action, Map<String, String> params) async {
    final user = currentUserGlobal;
    if (user == null) throw GasResponseException('Usuário não autenticado');

    final uri = Uri.parse(user.baseScriptUrl);
    final body = jsonEncode({
      'action': action,
      'storeId': user.storeId,
      ...params,
    });

    if (kDebugMode) print('[GAS] POST $uri → $body');

    _ensureClient();

    try {
      final resp = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 60));

      if (resp.statusCode != 200) {
        throw GasResponseException('HTTP ${resp.statusCode}', statusCode: resp.statusCode);
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['success'] == true) {
        return;
      } else {
        throw GasResponseException(decoded['error'] ?? 'Falha na ação');
      }
    } on http.ClientException catch (e) {
      if (e.message.contains('Client is already closed')) {
        _internalClient?.close();
        _internalClient = http.Client();
        if (kDebugMode) print('[GasApi] Cliente recriado em POST');
      }
      rethrow;
    } on SocketException {
      throw GasResponseException('Sem internet');
    } on TimeoutException {
      throw GasResponseException('Tempo esgotado no POST');
    } catch (e) {
      throw GasResponseException('Erro no POST: $e');
    }
  }

  /// Fecha e recria o cliente (chame apenas ao encerrar o app ou deslogar)
  static void dispose() {
    if (_internalClient != null) {
      if (kDebugMode) print('[GasApi] Fechando cliente HTTP...');
      _internalClient!.close();
      _internalClient = null; // Será recriado na próxima chamada
    }
  }
}