// lib/services/criar_pedido_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../globals.dart';

class CriarPedidoService {
  final AppUser user;  // ← Só para storeId e unidade

  const CriarPedidoService({required this.user});

  // === CHAVES COMPARTILHADAS ===
  static const String _consumerKey = 'ck_5156e2360f442f2585c8c9a761ef084b710e811f';
  static const String _consumerSecret = 'cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c';
  static const String _baseUrl = 'https://aogosto.com.br/delivery/';
  static const String _proxyUrl = 'https://aogosto.com.br/proxy/buscar-cliente-por-telefone.php';
  static const String _proxyCheckoutUrl = 'https://aogosto.com.br/proxy/checkout-flutter.php';

  String get _unitName => 'Unidade ${user.unidade}';

  Future<void> logToFile(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/sistema-erp-cd');
      if (!await appDir.exists()) await appDir.create(recursive: true);
      final file = File('${appDir.path}/criar_pedido_logs.txt');
      await file.writeAsString('[${DateTime.now()}] [$user.unidade] $message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Falha ao escrever log: $e');
    }
  }

  // === BUSCA CLIENTE ===
  Future<Map<String, dynamic>?> fetchCustomerByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    await logToFile('Buscando cliente: $cleanPhone');
    final searchPhone = cleanPhone.startsWith('55') ? cleanPhone.substring(2) : cleanPhone;
    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': searchPhone}),
      );
      await logToFile('Resposta: status=${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro: ${response.statusCode}');
      }
    } catch (error) {
      await logToFile('Erro: $error');
      throw Exception('Erro ao buscar cliente: $error');
    }
  }

  // === BUSCA PRODUTOS (COMPARTILHADO) ===
  Future<List<Map<String, dynamic>>> fetchProducts(String searchTerm) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/products?search=$searchTerm&per_page=20&consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> products = jsonDecode(response.body);
        return products.map((product) => {
              'id': product['id'],
              'name': product['name'],
              'price': double.tryParse(product['price']) ?? 0.0,
              'image': product['images'].isNotEmpty ? product['images'][0]['src'] : null,
              'type': product['type'],
              'variations': product['variations'],
              'stock_status': product['stock_status'] ?? 'outofstock',
            }).toList();
      } else {
        throw Exception('Erro ao buscar produtos: ${response.statusCode}');
      }
    } catch (error) {
      await logToFile('Erro ao buscar produtos: $error');
      throw Exception('Erro ao buscar produtos: $error');
    }
  }

  // === ATRIBUTOS E VARIAÇÕES (COMPARTILHADO) ===
  Future<List<Map<String, dynamic>>> fetchProductAttributes(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/products/$productId?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
      );
      if (response.statusCode == 200) {
        final product = jsonDecode(response.body);
        final attributes = product['attributes'] as List<dynamic>? ?? [];
        return attributes.map((attr) => {
              'name': attr['name'],
              'options': attr['options'] as List<dynamic>,
            }).toList();
      } else {
        throw Exception('Erro ao buscar atributos: ${response.statusCode}');
      }
    } catch (error) {
      await logToFile('Erro ao buscar atributos: $error');
      throw Exception('Erro ao buscar atributos: $error');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductVariations(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/products/$productId/variations?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> variations = jsonDecode(response.body);
        return variations.map((variation) => {
              'id': variation['id'],
              'attributes': variation['attributes'],
              'price': double.tryParse(variation['price']) ?? 0.0,
              'stock_status': variation['stock_status'] ?? 'outofstock',
            }).toList();
      } else {
        throw Exception('Erro ao buscar variações: ${response.statusCode}');
      }
    } catch (error) {
      await logToFile('Erro ao buscar variações: $error');
      throw Exception('Erro ao buscar variações: $error');
    }
  }

  // === DETERMINA LOJA POR CEP (GENÉRICO) ===
  Future<Map<String, dynamic>> fetchStoreDecision({
    required String cep,
    required String shippingMethod,
    String pickupStore = '',
    String deliveryDate = '',
    String pickupDate = '',
  }) async {
    try {
      final unitName = _unitName;
      final response = await http.post(
        Uri.parse('https://aogosto.com.br/delivery/wp-json/custom/v1/store-decision'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cep': cep,
          'shipping_method': shippingMethod,
          'pickup_store': pickupStore,
          'delivery_date': deliveryDate,
          'pickup_date': pickupDate,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao determinar loja: ${response.statusCode}');
      }
    } catch (error) {
      await logToFile('Erro ao determinar loja: $error');
      throw Exception('Erro ao determinar loja: $error');
    }
  }

  // === VALIDA CUPOM (COMPARTILHADO) ===
  Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    required List<Map<String, dynamic>> products,
    required double shippingCost,
  }) async {
    try {
      final lineItems = products.map((product) => {
        'product_id': product['id'],
        'name': product['name'],
        'quantity': product['quantity'] ?? 1,
        'subtotal': (product['price'] * (product['quantity'] ?? 1)).toStringAsFixed(2),
        'total': (product['price'] * (product['quantity'] ?? 1)).toStringAsFixed(2),
        if (product['variation_id'] != null) 'variation_id': product['variation_id'],
      }).toList();
      final payload = {
        'line_items': lineItems,
        'shipping_lines': [
          {'method_id': 'flat_rate', 'method_title': 'Taxa de Entrega', 'total': shippingCost.toStringAsFixed(2)},
        ],
        'coupon_lines': [{'code': couponCode}],
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 201) {
        final order = jsonDecode(response.body);
        final subtotal = products.fold<double>(0.0, (sum, product) => sum + ((product['price'] ?? 0.0) * (product['quantity'] ?? 1))) + shippingCost;
        final totalWithDiscount = double.tryParse(order['total']) ?? subtotal;
        final discount = subtotal - totalWithDiscount;
        await http.delete(
          Uri.parse('$_baseUrl/wp-json/wc/v3/orders/${order['id']}?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
        );
        return {'is_valid': true, 'discount_amount': discount, 'total_with_discount': totalWithDiscount};
      } else {
        final error = jsonDecode(response.body);
        return {'is_valid': false, 'error_message': error['message'] ?? 'Cupom inválido'};
      }
    } catch (error) {
      await logToFile('Erro ao validar cupom: $error');
      return {'is_valid': false, 'error_message': 'Erro ao validar o cupom: $error'};
    }
  }

  // === CRIA PEDIDO (COMPARTILHADO) ===
  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String billingCompany,
    required List<Map<String, dynamic>> products,
    required String shippingMethod,
    required String storeFinal,
    required String pickupStoreId,
    required String billingPostcode,
    required String billingAddress1,
    required String billingNumber,
    required String billingAddress2,
    required String billingNeighborhood,
    required String billingCity,
    required double shippingCost,
    required String paymentMethod,
    required String customerNotes,
    required String schedulingDate,
    required String schedulingTime,
    required String couponCode,
    required String paymentAccountStripe,
    required String paymentAccountPagarme,
  }) async {
    try {
      final effectiveShippingCost = shippingMethod == 'pickup' ? 0.0 : shippingCost;
      final lineItems = products.map((product) => {
        'product_id': product['id'],
        'name': product['name'],
        'quantity': product['quantity'] ?? 1,
        'subtotal': (product['price'] * (product['quantity'] ?? 1)).toStringAsFixed(2),
        'total': (product['price'] * (product['quantity'] ?? 1)).toStringAsFixed(2),
        if (product['variation_id'] != null) 'variation_id': product['variation_id'],
      }).toList();
      final nameParts = customerName.trim().split(' ').where((part) => part.isNotEmpty).toList();
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final orderStatus = (paymentMethod == 'pagarme_custom_pix' || paymentMethod == 'stripe')
          ? 'pending'
          : 'processing';
      final payload = {
        'payment_method': paymentMethod,
        'payment_method_title': {
          'pagarme_custom_pix': 'Pix On-line',
          'stripe': 'Cartão de Crédito On-line',
          'cod': 'Dinheiro na Entrega',
          'custom_729b8aa9fc227ff': 'Cartão na Entrega',
          'custom_e876f567c151864': 'Vale Alimentação',
        }[paymentMethod] ?? 'Método Desconhecido',
        'billing': {
          'first_name': firstName,
          'last_name': lastName,
          'company': billingCompany,
          'postcode': billingPostcode,
          'address_1': billingAddress1,
          'address_2': billingAddress2,
          'city': billingCity,
          'state': 'MG',
          'country': 'BR',
          'email': customerEmail.isNotEmpty ? customerEmail : 'orders@aogosto.com.br',
          'phone': customerPhone,
        },
        'shipping': {
          'first_name': firstName,
          'last_name': lastName,
          'postcode': billingPostcode,
          'address_1': billingAddress1,
          'number': billingNumber,
          'address_2': billingAddress2,
          'neighborhood': billingNeighborhood,
          'city': billingCity,
          'state': 'MG',
          'country': 'BR',
        },
        'line_items': lineItems,
        'shipping_lines': [
          {
            'method_id': shippingMethod == 'delivery' ? 'flat_rate' : 'local_pickup',
            'method_title': shippingMethod == 'delivery' ? 'Motoboy' : 'Retirada na $_unitName',
            'total': effectiveShippingCost.toStringAsFixed(2),
          }
        ],
        'meta_data': [
          {'key': '_store_final', 'value': storeFinal},
          {'key': '_effective_store_final', 'value': storeFinal},
          {'key': '_billing_number', 'value': billingNumber},
          {'key': '_billing_neighborhood', 'value': billingNeighborhood},
          {'key': '_payment_account_stripe', 'value': paymentAccountStripe},
          {'key': '_payment_account_pagarme', 'value': paymentAccountPagarme},
          {'key': '_is_future_date', 'value': schedulingDate != DateFormat('yyyy-MM-dd').format(DateTime.now()) ? 'yes' : 'no'},
          if (shippingMethod == 'pickup') ...[
            {'key': '_shipping_pickup_stores', 'value': storeFinal},
            {'key': '_shipping_pickup_store_id', 'value': pickupStoreId},
            {'key': 'pickup_date', 'value': schedulingDate},
            {'key': 'pickup_time', 'value': schedulingTime},
          ],
          if (shippingMethod == 'delivery') ...[
            {'key': 'delivery_date', 'value': schedulingDate},
            {'key': 'delivery_time', 'value': schedulingTime},
          ],
          {'key': 'delivery_type', 'value': shippingMethod},
        ],
        'customer_note': customerNotes.isNotEmpty ? customerNotes : null,
        'status': orderStatus,
        if (couponCode.isNotEmpty) 'coupon_lines': [{'code': couponCode}],
      };
      await logToFile('Criando pedido: payload=${jsonEncode(payload)}');
      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      await logToFile('Resposta: status=${response.statusCode}');
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao criar pedido: ${response.statusCode}');
      }
    } catch (error) {
      await logToFile('Erro ao criar pedido: $error');
      throw Exception('Erro ao criar pedido: $error');
    }
  }
}