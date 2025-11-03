// lib/services/criar_pedido_gas.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart';

/// Serviço para buscar produtos, atributos e variações via Google Apps Script
class CriarPedidoGas {
  final AppUser user;

  const CriarPedidoGas({required this.user});

  /// Constrói a URL com parâmetros
  Uri _buildUri(String action, Map<String, String> params) {
    return Uri.parse(user.baseScriptUrl).replace(queryParameters: {
      'action': action,
      'storeId': user.storeId,
      ...params,
    });
  }

  /// Busca produtos por texto
  Future<List<Map<String, dynamic>>> fetchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final params = {'query': query.trim()};
    final uri = _buildUri('SearchProducts${user.unidade.replaceAll(' ', '')}', params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Erro HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Resposta inválida: $decoded');
      }
    } catch (e) {
      throw Exception('Falha ao buscar produtos: $e');
    }
  }

  /// Busca atributos de um produto
  Future<List<Map<String, dynamic>>> fetchProductAttributes(String productId) async {
    if (productId.isEmpty) return [];

    final params = {'product_id': productId};
    final uri = _buildUri('GetProductAttributes${user.unidade.replaceAll(' ', '')}', params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Erro HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Resposta inválida: $decoded');
      }
    } catch (e) {
      throw Exception('Falha ao buscar atributos: $e');
    }
  }

  /// Busca variações de um produto
  Future<List<Map<String, dynamic>>> fetchProductVariations(String productId) async {
    if (productId.isEmpty) return [];

    final params = {'product_id': productId};
    final uri = _buildUri('GetProductVariations${user.unidade.replaceAll(' ', '')}', params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Erro HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Resposta inválida: $decoded');
      }
    } catch (e) {
      throw Exception('Falha ao buscar variações: $e');
    }
  }
}