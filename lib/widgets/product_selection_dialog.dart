// lib/widgets/product_selection_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../globals.dart';
import '../services/criar_pedido_gas.dart';

class ProductSelectionDialog extends StatefulWidget {
  final CriarPedidoGas gasService;

  const ProductSelectionDialog({
    Key? key,
    required this.gasService,
  }) : super(key: key);

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  final primaryColor = const Color(0xFFF28C38);
  late final CriarPedidoGas _gasService;

  @override
  void initState() {
    super.initState();
    _gasService = widget.gasService;
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _log(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final unidade = (currentUserGlobal?.unidade ?? 'Desconhecida')
          .replaceAll(' ', '_')
          .toLowerCase();
      final appDir = Directory('${dir.path}/ERPUnificado/$unidade');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final file = File('${appDir.path}/app_logs.txt');
      await file.writeAsString(
        '[${DateTime.now()}] [BuscaProduto] $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Falha ao logar busca: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 3) {
      _fetchProducts(query);
    } else {
      setState(() => _products = []);
    }
  }

  Future<void> _fetchProducts(String query) async {
    setState(() => _isLoading = true);
    try {
      final products = await _gasService.fetchProducts(query);
      setState(() => _products = products);
      await _log('Busca: "$query" → ${products.length} produtos encontrados');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar produtos: $e'), backgroundColor: Colors.redAccent),
        );
      }
      await _log('Erro na busca: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _showVariationDialog(Map<String, dynamic> product) async {
    try {
      final attributes = await _gasService.fetchProductAttributes(product['id'].toString());
      final variations = await _gasService.fetchProductVariations(product['id'].toString());

      final Map<String, String> selectedAttributes = {};
      for (var attr in attributes) {
        final options = attr['options'] as List<dynamic>;
        if (options.isNotEmpty) {
          selectedAttributes[attr['name']] = options.first.toString();
        }
      }

      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              List<Map<String, dynamic>> availableVariations = variations
                  .where((v) {
                    final attrs = v['attributes'] as List<dynamic>;
                    return attrs.every((a) =>
                        selectedAttributes[a['name']] == a['option']);
                  })
                  .cast<Map<String, dynamic>>()
                  .toList();

              final selected = availableVariations.firstWhereOrNull(
                  (v) => v['stock_status'] == 'instock');

              return AlertDialog(
                title: Text(
                  'Variações - ${currentUserGlobal?.unidade ?? 'CD'}',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...attributes.map((attr) {
                        final options = attr['options'] as List<dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DropdownButtonFormField<String>(
                            value: selectedAttributes[attr['name']],
                            decoration: _inputDecoration(attr['name'] ?? '', Icons.label), // CORRIGIDO: 2 argumentos
                            items: options.map((opt) {
                              return DropdownMenuItem(
                                value: opt.toString(),
                                child: Text(opt.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedAttributes[attr['name']] = value!;
                              });
                            },
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      if (availableVariations.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: availableVariations.map((v) {
                            final inStock = v['stock_status'] == 'instock';
                            final price = v['price']?.toString() ?? '0.00';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('R\$ $price', style: GoogleFonts.poppins(fontSize: 14)),
                                  ),
                                  Row(
                                    children: [
                                      Icon(inStock ? Icons.check_circle : Icons.cancel,
                                          color: inStock ? Colors.green.shade600 : Colors.redAccent, size: 16),
                                      const SizedBox(width: 4),
                                      Text(inStock ? 'Em Estoque' : 'Fora de Estoque',
                                          style: GoogleFonts.poppins(fontSize: 12, color: inStock ? Colors.green.shade600 : Colors.redAccent)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text('Nenhuma variação disponível.', style: GoogleFonts.poppins(color: Colors.redAccent)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.redAccent)),
                  ),
                  ElevatedButton(
                    onPressed: selected != null
                        ? () {
                            final attrs = selectedAttributes.entries
                                .map((e) => {'name': e.key, 'option': e.value})
                                .toList();
                            Navigator.pop(context, {
                              'id': selected['id'],
                              'price': selected['price'],
                              'attributes': attrs,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: Text('Confirmar', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      await _log('Erro em _showVariationDialog: $e');
      return null;
    }
  }

  void _selectProduct(Map<String, dynamic> product) async {
    final inStock = product['stock_status'] == 'instock';
    if (!inStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto fora de estoque')));
      return;
    }

    if (product['type'] == 'variable') {
      final variation = await _showVariationDialog(product);
      if (variation != null && mounted) {
        Navigator.of(context).pop({
          'id': product['id'],
          'name': product['name'],
          'price': variation['price'],
          'variation_id': variation['id'],
          'variation_attributes': variation['attributes'],
          'image': product['image'],
        });
      }
    } else {
      Navigator.of(context).pop({
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'variation_id': null,
        'variation_attributes': null,
        'image': product['image'],
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unidade = currentUserGlobal?.unidade ?? 'CD';

    return AlertDialog(
      title: Text(
        'Selecionar Produto - $unidade',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: _inputDecoration('Buscar Produto (mín. 3 caracteres)', Icons.search), // CORRIGIDO
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor))
            else if (_products.isEmpty && _searchController.text.length >= 3)
              Text('Nenhum produto encontrado', style: GoogleFonts.poppins(color: Colors.grey.shade600))
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    final inStock = p['stock_status'] == 'instock';
                    final price = p['price']?.toString() ?? '0.00';
                    return Opacity(
                      opacity: inStock ? 1.0 : 0.5,
                      child: Card(
                        child: ListTile(
                          leading: p['image'] != null && p['image'].toString().isNotEmpty
                              ? Image.network(
                                  p['image'].toString(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey.shade600),
                                )
                              : Icon(Icons.image_not_supported, color: Colors.grey.shade600),
                          title: Text(p['name'].toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('R\$ $price', style: GoogleFonts.poppins(fontSize: 14)),
                              Row(
                                children: [
                                  Icon(inStock ? Icons.check_circle : Icons.cancel,
                                      color: inStock ? Colors.green.shade600 : Colors.redAccent, size: 16),
                                  const SizedBox(width: 4),
                                  Text(inStock ? 'Em Estoque' : 'Fora de Estoque',
                                      style: GoogleFonts.poppins(fontSize: 12, color: inStock ? Colors.green.shade600 : Colors.redAccent)),
                                ],
                              ),
                            ],
                          ),
                          onTap: inStock ? () => _selectProduct(p) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.redAccent)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) { // CORRIGIDO: 2 parâmetros
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}