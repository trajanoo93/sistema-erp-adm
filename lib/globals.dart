// lib/globals.dart
class AppUser {
  final int id;
  final String nome;
  final String unidade;
  final String readAction;
  final String markPrintedAction;
  final String unmarkPrintedAction;
  final String updateStatusAction;
  final String baseScriptUrl;
  final String storeId;
  final String whatsappNumber;  

  AppUser({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.readAction,
    required this.markPrintedAction,
    required this.unmarkPrintedAction,
    required this.updateStatusAction,
    required this.baseScriptUrl,
    required this.storeId,
    required this.whatsappNumber,  
  });

  @override
  String toString() => 'AppUser($nome, $unidade)';
}

/// === MAPEAMENTO DE UNIDADES ===
final Map<String, String> _storeIds = {
  'Barreiro': '110727',
  'Sion': '127163',
  'Lagoa Santa': '131813',
};

/// === USUÁRIOS AUTENTICADOS ===
final Map<int, AppUser> appUsers = {
  4: AppUser(
    id: 4,
    nome: 'Paulo',
    unidade: 'Barreiro',
    readAction: 'ReadCD',
    markPrintedAction: 'MarkPrinted',
    unmarkPrintedAction: 'UnmarkPrinted',
    updateStatusAction: 'UpdateStatusPedidoCD',
    baseScriptUrl: 'https://script.google.com/macros/s/AKfycbzukU2hVxn6tRA_OZH-wXWx4wqTSWa7TeMcMPX7UGr1t6oedrmJzNBo6Qx3tak6Qbw5/exec',
    storeId: _storeIds['Barreiro']!,
    whatsappNumber: '5531995348704',  
  ),
  110: AppUser(
    id: 110,
    nome: 'Mylene',
    unidade: 'Sion',
    readAction: 'ReadCD',
    markPrintedAction: 'MarkPrinted',
    unmarkPrintedAction: 'UnmarkPrinted',
    updateStatusAction: 'UpdateStatusPedidoCD',  
    baseScriptUrl: 'https://script.google.com/macros/s/AKfycbzukU2hVxn6tRA_OZH-wXWx4wqTSWa7TeMcMPX7UGr1t6oedrmJzNBo6Qx3tak6Qbw5/exec',
    storeId: _storeIds['Sion']!,
    whatsappNumber: '5531995348705', 
  ),
  83: AppUser(
    id: 83,
    nome: 'Lincoln',
    unidade: 'Lagoa Santa',
    readAction: 'ReadCD',
    markPrintedAction: 'MarkPrinted',
    unmarkPrintedAction: 'UnmarkPrinted',
    updateStatusAction: 'UpdateStatusPedidoCD', 
    baseScriptUrl: 'https://script.google.com/macros/s/AKfycbzukU2hVxn6tRA_OZH-wXWx4wqTSWa7TeMcMPX7UGr1t6oedrmJzNBo6Qx3tak6Qbw5/exec',
    storeId: _storeIds['Lagoa Santa']!,
    whatsappNumber: '5531995348705',  
  ),
};

/// === USUÁRIO ATUAL (GLOBAL) ===
AppUser? currentUser;