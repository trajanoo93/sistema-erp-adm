// lib/widgets/product_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../globals.dart'; // ← currentUserGlobal
import 'product_selection_dialog.dart';

class ProductSection extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(int) onRemoveProduct;
  final VoidCallback onAddProduct;
  final Function(int, int) onUpdateQuantity;
  final Function(int, double)? onUpdatePrice;

  const ProductSection({
    Key? key,
    required this.products,
    required this.onRemoveProduct,
    required this.onAddProduct,
    required this.onUpdateQuantity,
    this.onUpdatePrice,
  }) : super(key: key);

  @override
  State<ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<ProductSection> {
  final primaryColor = const Color(0xFFF28C38);

  /// Salva log por unidade
  Future<void> _log(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final unidade = (currentUserGlobal?.unidade ?? 'Desconhecida').replaceAll(' ', '_').toLowerCase(); // CORRIGIDO
      final appDir = Directory('${dir.path}/ERPUnificado/$unidade');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);

      final file = File('${appDir.path}/app_logs.txt');
      await file.writeAsString('[${DateTime.now()}] [Produtos] $message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Falha ao logar produto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidade = currentUserGlobal?.unidade ?? 'CD'; // CORRIGIDO

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Produtos - $unidade',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...widget.products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = Map<String, dynamic>.from(entry.value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagem
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product['image'] != null && product['image'].toString().isNotEmpty
                          ? Image.network(
                              product['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
                                onPressed: () {
                                  _log('Produto removido: ${product['name']} (ID: ${product['id']})');
                                  widget.onRemoveProduct(index);
                                },
                              ),
                            ],
                          ),
                          // Variações
                          if (product['variation_attributes'] is List && product['variation_attributes'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...product['variation_attributes'].map<Widget>((attr) {
                              return Text(
                                '${attr['name'] ?? 'Atributo'}: ${attr['option'] ?? 'Desconhecido'}',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              );
                            }).toList(),
                          ],
                          const SizedBox(height: 12),
                          // Preço + Quantidade
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: product['price'].toStringAsFixed(2),
                                  decoration: _inputDecoration('Preço (R\$)'),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) {
                                    final newPrice = double.tryParse(value.replaceAll(',', '.')) ?? product['price'];
                                    _log('Preço alterado: ${product['name']} → R\$ $newPrice');
                                    widget.onUpdatePrice?.call(index, newPrice);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Insira o preço';
                                    if (double.tryParse(value.replaceAll(',', '.')) == null || double.parse(value.replaceAll(',', '.')) <= 0)
                                      return 'Preço > 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: product['quantity'].toString(),
                                  decoration: _inputDecoration('Quantidade'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final newQty = int.tryParse(value) ?? product['quantity'];
                                    _log('Quantidade alterada: ${product['name']} → $newQty');
                                    widget.onUpdateQuantity(index, newQty);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Insira a qtd';
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Qtd > 0';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _log('Botão "Adicionar Produto" clicado');
                widget.onAddProduct();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Text(
                'Adicionar Produto',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey.shade200,
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade600, size: 30),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}