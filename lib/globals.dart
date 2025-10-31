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

  // NOVO: storeId dinâmico
  String get storeId {
    return unidade.toLowerCase().replaceAll(' ', '_');
  }

  AppUser({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.readAction,
    required this.markPrintedAction,
    required this.unmarkPrintedAction,
    required this.updateStatusAction,
    required this.baseScriptUrl,
  });
}

// === DADOS DOS USUÁRIOS (MANTIDOS, MAS AGORA COM storeId DINÂMICO) ===
final Map<int, AppUser> appUsers = {
  110: AppUser(
    id: 110,
    nome: 'Mylene',
    unidade: 'Sion',
    readAction: 'ReadCDSion',
    markPrintedAction: 'MarkPrintedSion',
    unmarkPrintedAction: 'UnmarkPrintedSion',
    updateStatusAction: 'UpdateStatusPedidoSion',
    baseScriptUrl: 'https://script.google.com/macros/s/AKfycbz4J0iFumPBam_dSDAra31NHMJ29ze-Ykf64JkjqLTqRukR7j0MF5_tZe2Q-_BZgijW/exec',
  ),
  83: AppUser(
    id: 83,
    nome: 'Lincoln',
    unidade: 'Lagoa Santa',
    readAction: 'ReadCDLagoaSanta',
    markPrintedAction: 'MarkPrintedLagoaSanta',
    unmarkPrintedAction: 'UnmarkPrintedLagoaSanta',
    updateStatusAction: 'UpdateStatusPedidoLagoaSanta',
    baseScriptUrl: 'https://script.google.com/macros/s/AKfycbz4J0iFumPBam_dSDAra31NHMJ29ze-Ykf64JkjqLTqRukR7j0MF5_tZe2Q-_BZgijW/exec',
  ),
  4: AppUser(
    id: 4,
    nome: 'Paulo',
    unidade: 'Barreiro',
    readAction: 'ReadCDBarreiro',
    markPrintedAction: 'MarkPrintedBarreiro',
    unmarkPrintedAction: 'UnmarkPrintedBarreiro',
    updateStatusAction: 'UpdateStatusPedidoBarreiro',
    baseScriptUrl: 'https://script.google.com/macros/s/AKfycbz4J0iFumPBam_dSDAra31NHMJ29ze-Ykf64JkjqLTqRukR7j0MF5_tZe2Q-_BZgijW/exec',
  ),
};

// URL base comum
const String defaultBaseScriptUrl = 'https://script.google.com/macros/s/AKfycbz4J0iFumPBam_dSDAra31NHMJ29ze-Ykf64JkjqLTqRukR7j0MF5_tZe2Q-_BZgijW/exec';

// Variáveis globais
AppUser? currentUser;

// === FUNÇÕES GLOBAIS DINÂMICAS ===
String getCurrentStoreId() => currentUser?.storeId ?? '';
String getCurrentUnidade() => currentUser?.unidade ?? '';
bool isLoggedIn() => currentUser != null;