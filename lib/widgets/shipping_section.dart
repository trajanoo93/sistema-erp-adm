// lib/widgets/shipping_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sistema_erp_cd/models/pedido_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../globals.dart'; // ← currentUser

class ShippingSection extends StatefulWidget {
  final String cep;
  final Function(String, String) onStoreUpdated;
  final Function(String) onShippingMethodUpdated;
  final Function(double) onShippingCostUpdated;
  final PedidoState pedido;
  final Function() onSchedulingChanged;
  final Future<void> Function(PedidoState)? savePersistedData;

  const ShippingSection({
    Key? key,
    required this.cep,
    required this.onStoreUpdated,
    required this.onShippingMethodUpdated,
    required this.onShippingCostUpdated,
    required this.pedido,
    required this.onSchedulingChanged,
    this.savePersistedData,
  }) : super(key: key);

  @override
  State<ShippingSection> createState() => _ShippingSectionState();
}

class _ShippingSectionState extends State<ShippingSection> {
  String _shippingMethod = 'delivery';
  final primaryColor = const Color(0xFFF28C38);

  // DINÂMICO POR USUÁRIO
  String get _unitName => 'Unidade ${currentUser?.unidade ?? 'CD'}';
  String get _storeId => currentUser?.storeId ?? '110727';

  Future<void> _log(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final unidade = (currentUser?.unidade ?? 'Desconhecida').replaceAll(' ', '_').toLowerCase();
      final appDir = Directory('${dir.path}/ERPUnificado/$unidade');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final file = File('${appDir.path}/app_logs.txt');
      await file.writeAsString('[${DateTime.now()}] [Entrega] $message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Falha ao logar entrega: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _shippingMethod = widget.pedido.shippingMethod.isNotEmpty ? widget.pedido.shippingMethod : 'delivery';
    _updatePickupIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onShippingMethodUpdated(_shippingMethod);
        widget.onStoreUpdated(widget.pedido.storeFinal, widget.pedido.pickupStoreId);
        widget.onShippingCostUpdated(widget.pedido.shippingCost);
        _fetchStoreDecision(widget.cep);
        _log('initState: method=$_shippingMethod, store=${widget.pedido.storeFinal}');
      }
    });
  }

  @override
  void didUpdateWidget(ShippingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cep != widget.cep || oldWidget.pedido.shippingMethod != widget.pedido.shippingMethod) {
      _updatePickupIfNeeded();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onStoreUpdated(widget.pedido.storeFinal, widget.pedido.pickupStoreId);
          widget.onShippingCostUpdated(widget.pedido.shippingCost);
          _fetchStoreDecision(widget.cep);
          _log('didUpdate: cep=${widget.cep}, method=$_shippingMethod');
        }
      });
    }
  }

  void _updatePickupIfNeeded() {
    if (_shippingMethod == 'pickup') {
      widget.pedido.storeFinal = _unitName;
      widget.pedido.pickupStoreId = _storeId;
      widget.pedido.shippingCost = 0.0;
      widget.pedido.shippingCostController.text = '0.00';
    }
  }

  Future<void> _fetchStoreDecision(String cep) async {
    await _log('Buscando loja para CEP: $cep, método: $_shippingMethod');
    if (_shippingMethod == 'pickup') {
      setState(() {
        widget.pedido.storeFinal = _unitName;
        widget.pedido.pickupStoreId = _storeId;
        widget.pedido.shippingCost = 0.0;
        widget.pedido.shippingCostController.text = '0.00';
      });
      widget.onShippingCostUpdated(0.0);
      widget.onStoreUpdated(_unitName, _storeId);
      widget.pedido.notifyListeners();
      await _log('Pickup: $_unitName ($_storeId)');
      widget.savePersistedData?.call(widget.pedido);
      return;
    }

    if (cep.length != 8) {
      await _log('CEP inválido');
      setState(() {
        widget.pedido.storeFinal = '';
        widget.pedido.pickupStoreId = '';
        widget.pedido.availablePaymentMethods = [];
        widget.pedido.paymentAccounts = {'stripe': 'stripe', 'pagarme': 'central'};
        widget.pedido.shippingCost = 0.0;
        widget.pedido.shippingCostController.text = '0.00';
      });
      widget.onShippingCostUpdated(0.0);
      widget.onStoreUpdated('', '');
      widget.pedido.notifyListeners();
      widget.savePersistedData?.call(widget.pedido);
      return;
    }

    try {
      final normalizedDate = widget.pedido.schedulingDate.isEmpty
          ? DateFormat('yyyy-MM-dd').format(DateTime.now())
          : widget.pedido.schedulingDate;
      final requestBody = {
        'cep': cep,
        'shipping_method': _shippingMethod,
        'pickup_store': _shippingMethod == 'pickup' ? _unitName : '',
        'delivery_date': _shippingMethod == 'delivery' ? normalizedDate : '',
        'pickup_date': _shippingMethod == 'pickup' ? normalizedDate : '',
      };
      await _log('Enviando: ${jsonEncode(requestBody)}');
      final storeResponse = await http.post(
        Uri.parse('https://aogosto.com.br/delivery/wp-json/custom/v1/store-decision'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      await _log('Resposta: ${storeResponse.statusCode}');

      double shippingCost = 0.0;
      if (_shippingMethod == 'delivery') {
        final costResponse = await http.get(
          Uri.parse('https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=$cep'),
        ).timeout(const Duration(seconds: 15));
        if (costResponse.statusCode == 200) {
          final costData = jsonDecode(costResponse.body);
          shippingCost = double.tryParse(costData['shipping_options']?[0]?['cost']?.toString() ?? '0.0') ?? 0.0;
        }
      }

      if (storeResponse.statusCode == 200) {
        final data = jsonDecode(storeResponse.body);
        setState(() {
          widget.pedido.storeFinal = data['effective_store_final'] ?? data['store_final'] ?? '';
          widget.pedido.pickupStoreId = data['pickup_store_id'] ?? '';
          // ... (payment methods igual)
          widget.pedido.shippingCost = shippingCost;
          widget.pedido.shippingCostController.text = shippingCost.toStringAsFixed(2);
        });
        widget.onStoreUpdated(widget.pedido.storeFinal, widget.pedido.pickupStoreId);
        widget.onShippingCostUpdated(shippingCost);
        widget.pedido.notifyListeners();
        await _log('Loja definida: ${widget.pedido.storeFinal}');
        widget.savePersistedData?.call(widget.pedido);
      }
    } catch (e) {
      await _log('Erro: $e');
      // fallback
      setState(() {
        widget.pedido.storeFinal = '';
        widget.pedido.pickupStoreId = '';
        widget.pedido.shippingCost = 0.0;
        widget.pedido.shippingCostController.text = '0.00';
      });
      widget.onStoreUpdated('', '');
      widget.onShippingCostUpdated(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              'Método de Entrega',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _shippingMethod,
              decoration: InputDecoration(
                labelText: 'Método de Entrega',
                labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                prefixIcon: Icon(Icons.local_shipping, color: primaryColor),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                DropdownMenuItem(value: 'pickup', child: Text('Retirada na $_unitName')), // DINÂMICO
              ],
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() => _shippingMethod = value);
                  _updatePickupIfNeeded();
                  widget.onShippingMethodUpdated(_shippingMethod);
                  widget.onStoreUpdated(widget.pedido.storeFinal, widget.pedido.pickupStoreId);
                  widget.onShippingCostUpdated(widget.pedido.shippingCost);
                  widget.pedido.notifyListeners();
                  _log('Método: $_shippingMethod');
                  widget.savePersistedData?.call(widget.pedido);
                  _fetchStoreDecision(widget.cep);
                }
              },
            ),
          ),
          if (_shippingMethod == 'pickup') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: primaryColor, width: 4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Retirada na loja: $_unitName',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.orange[800], fontWeight: FontWeight.w500),
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
}