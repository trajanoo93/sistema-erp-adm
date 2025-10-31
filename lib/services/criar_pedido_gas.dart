// lib/services/criar_pedido_gas.dart (adicione no final do arquivo)

  Future<List<Map<String, dynamic>>> fetchProducts(String query) async {
    final params = {'query': query};
    final uri = _buildUri('SearchProducts${user.unidade.replaceAll(' ', '')}', params);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erro ao buscar produtos');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchProductAttributes(String productId) async {
    final params = {'product_id': productId};
    final uri = _buildUri('GetProductAttributes${user.unidade.replaceAll(' ', '')}', params);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erro ao buscar atributos');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchProductVariations(String productId) async {
    final params = {'product_id': productId};
    final uri = _buildUri('GetProductVariations${user.unidade.replaceAll(' ', '')}', params);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erro ao buscar variações');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }