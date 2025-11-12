// lib/pages/pedidos_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../design_system.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);
  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  // FILTROS
  String _cdFiltro = 'CD Central';
  DateTime? _dataInicial;
  DateTime? _dataFinal;
  String _busca = '';
  Set<String> _statusFiltros = {}; // Múltiplos status selecionados

  final _cds = ['CD Central', 'CD Sion', 'CD Barreiro', 'CD Lagoa Santa', 'Todos'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _busca = _searchController.text.toLowerCase()));
    // Define data inicial e final como hoje por padrão
    final hoje = DateTime.now();
    _dataInicial = DateTime(hoje.year, hoje.month, hoje.day);
    _dataFinal = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _buildHeaderCompacto(),
          _buildFiltrosCompactos(),
          Expanded(child: _buildPedidosStream()),
        ],
      ),
    );
  }

  // ========================================
  // HEADER MINIMALISTA E COMPACTO
  // ========================================
  Widget _buildHeaderCompacto() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          // ÍCONE + TÍTULO
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOpacity12,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primaryOpacity25),
            ),
            child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestão de Pedidos', style: AppTypography.sectionTitle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sistema online',
                      style: AppTypography.caption.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ESTATÍSTICAS RÁPIDAS
          _buildStatsMini(),
        ],
      ),
    );
  }

  Widget _buildStatsMini() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        final total = docs.length;
        final pendentes = docs.where((d) {
          final status = (d.data() as Map)['status'] ?? 'Processando';
          return ['Pendente', 'Processando', 'Registrado'].contains(status);
        }).length;
        final concluidos = docs.where((d) {
          final status = (d.data() as Map)['status'] ?? '';
          return status == 'Concluído';
        }).length;

        return Row(
          children: [
            _buildStatMini('Total', total.toString(), AppColors.primary, Icons.shopping_cart_rounded),
            const SizedBox(width: 12),
            _buildStatMini('Pendentes', pendentes.toString(), AppColors.warning, Icons.pending_actions_rounded),
            const SizedBox(width: 12),
            _buildStatMini('Concluídos', concluidos.toString(), AppColors.success, Icons.check_circle_rounded),
          ],
        );
      },
    );
  }

  Widget _buildStatMini(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.label.copyWith(color: color, fontSize: 14)),
              Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // FILTROS COMPACTOS E HARMONIOSOS
  // ========================================
  Widget _buildFiltrosCompactos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Column(
        children: [
          // LINHA 1: BUSCA
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID, nome, bairro...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _busca.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _busca = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // LINHA 2: FILTROS
          Row(
            children: [
              // CD
              Expanded(
                flex: 2,
                child: _buildFilterButton(
                  icon: Icons.warehouse_rounded,
                  child: DropdownButton<String>(
                    value: _cdFiltro,
                    items: _cds.map((cd) => DropdownMenuItem(
                      value: cd,
                      child: Text(cd, style: AppTypography.bodySmall),
                    )).toList(),
                    onChanged: (v) => setState(() => _cdFiltro = v!),
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // DATA INICIAL
              Expanded(
                flex: 2,
                child: _buildFilterButton(
                  icon: Icons.calendar_today_rounded,
                  label: _dataInicial == null ? 'Data inicial' : DateFormat('dd/MM/yy').format(_dataInicial!),
                  onTap: () => _selecionarData(true),
                ),
              ),
              const SizedBox(width: 8),
              // DATA FINAL
              Expanded(
                flex: 2,
                child: _buildFilterButton(
                  icon: Icons.event_rounded,
                  label: _dataFinal == null ? 'Data final' : DateFormat('dd/MM/yy').format(_dataFinal!),
                  onTap: () => _selecionarData(false),
                ),
              ),
              const SizedBox(width: 8),
              // STATUS (MÚLTIPLA SELEÇÃO)
              Expanded(
                flex: 2,
                child: _buildFilterButton(
                  icon: Icons.filter_list_rounded,
                  label: _statusFiltros.isEmpty 
                      ? 'Todos os status' 
                      : '${_statusFiltros.length} selecionado${_statusFiltros.length > 1 ? 's' : ''}',
                  onTap: _abrirFiltroStatus,
                ),
              ),
              const SizedBox(width: 8),
              // LIMPAR FILTROS
              if (_busca.isNotEmpty || _statusFiltros.isNotEmpty)
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.clear_all_rounded, color: AppColors.error, size: 20),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _busca = '';
                        _statusFiltros.clear();
                      });
                    },
                    tooltip: 'Limpar Filtros',
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    String? label,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            if (label != null)
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (child != null)
              Expanded(child: child),
          ],
        ),
      ),
    );
  }

  // ========================================
  // MODAL DE FILTRO DE STATUS (CHECKBOXES)
  // ========================================
  void _abrirFiltroStatus() {
    showDialog(
      context: context,
      builder: (context) => _FiltroStatusDialog(
        statusSelecionados: Set.from(_statusFiltros),
        onConfirmar: (selecionados) {
          setState(() => _statusFiltros = selecionados);
        },
      ),
    );
  }

  Future<void> _selecionarData(bool isInicial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isInicial
          ? (_dataInicial ?? DateTime.now())
          : (_dataFinal ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isInicial) {
          _dataInicial = DateTime(date.year, date.month, date.day);
        } else {
          _dataFinal = DateTime(date.year, date.month, date.day, 23, 59, 59);
        }
      });
    }
  }

  // ========================================
  // LISTA DE PEDIDOS COM STREAM
  // ========================================
  Widget _buildPedidosStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar pedidos', style: AppTypography.cardTitle),
                const SizedBox(height: 8),
                Text(snapshot.error.toString(), style: AppTypography.caption, textAlign: TextAlign.center),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator(size: 40));
        }

        final docs = snapshot.data!.docs;
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] == '-' ? 'Processando' : (data['status'] ?? 'Processando');
          final cliente = data['cliente'] as Map<String, dynamic>?;
          final endereco = data['endereco'] as Map<String, dynamic>?;
          final id = data['id']?.toString() ?? '';
          final nome = cliente?['nome']?.toString().toLowerCase() ?? '';
          final bairro = endereco?['bairro']?.toString().toLowerCase() ?? '';

          final matchesBusca = _busca.isEmpty || id.contains(_busca) || nome.contains(_busca) || bairro.contains(_busca);
          final matchesStatus = _statusFiltros.isEmpty || _statusFiltros.contains(status);

          return matchesBusca && matchesStatus;
        }).toList();

        if (filtered.isEmpty) {
          return AppEmptyState(
            icon: Icons.inbox_rounded,
            title: 'Nenhum pedido encontrado',
            message: _busca.isNotEmpty || _statusFiltros.isNotEmpty
                ? 'Tente ajustar os filtros para encontrar o que procura'
                : 'Ainda não há pedidos registrados para este período',
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildPedidoCard(
            filtered[i].data() as Map<String, dynamic>,
            filtered[i].id,
          ),
        );
      },
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('is_ativo', isEqualTo: true);

    if (_cdFiltro != 'Todos') {
      query = query.where('cd', isEqualTo: _cdFiltro);
    }

    // FILTRO POR INTERVALO DE DATAS
    if (_dataInicial != null && _dataFinal != null) {
      query = query
          .where('agendamento.data', isGreaterThanOrEqualTo: _dataInicial)
          .where('agendamento.data', isLessThanOrEqualTo: _dataFinal);
    } else if (_dataInicial != null) {
      query = query.where('agendamento.data', isGreaterThanOrEqualTo: _dataInicial);
    } else if (_dataFinal != null) {
      query = query.where('agendamento.data', isLessThanOrEqualTo: _dataFinal);
    }

    query = query
        .orderBy('agendamento.data', descending: true)
        .orderBy('agendamento.janela_texto');

    return query;
  }

  // ========================================
  // CARD DE PEDIDO MINIMALISTA
  // ========================================
  Widget _buildPedidoCard(Map<String, dynamic> data, String id) {
    final status = data['status'] == '-' ? 'Processando' : (data['status'] ?? 'Processando');
    final color = _getStatusColor(status);

    final cliente = data['cliente'] as Map<String, dynamic>?;
    final endereco = data['endereco'] as Map<String, dynamic>?;
    final pagamento = data['pagamento'] as Map<String, dynamic>?;
    final agendamento = data['agendamento'] as Map<String, dynamic>?;

    final slot = agendamento?['janela_texto'] ?? 'Sem slot';
    final bairro = endereco?['bairro'] ?? 'Bairro não informado';
    final entregador = data['entregador'] == '-' ? 'Sem entregador' : (data['entregador'] ?? 'Sem entregador');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _abrirDetalhes(data, id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LINHA 1: ID + STATUS (COLORIDO E DESTACADO)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$id',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // BADGE COLORIDO E DESTACADO
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(status), size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // LINHA 2: CLIENTE + CD
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cliente?['nome'] ?? 'Cliente',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOpacity12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['cd'] ?? 'CD',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // LINHA 3: LOCALIZAÇÃO + ENTREGADOR
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(bairro, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.motorcycle_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(entregador, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const Divider(height: 16),
                // LINHA 4: PAGAMENTO + HORÁRIO
                Row(
                  children: [
                    Icon(_getPaymentIcon(pagamento?['metodo_principal']), size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      pagamento?['metodo_principal'] ?? 'Pagamento',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      slot,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // HELPERS
  // ========================================
  List<String> _getStatusList() {
    return [
      'Pendente',
      'Processando',
      'Registrado',
      'Agendado',
      'Saiu pra Entrega',
      'Concluído',
      'Cancelado',
      'Publi',
      'Retirado'
    ];
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pendente' => AppColors.warning,
      'Processando' => AppColors.info,
      'Registrado' => const Color(0xFF9C27B0),
      'Agendado' => const Color(0xFF3F51B5),
      'Saiu pra Entrega' => AppColors.success,
      'Concluído' => const Color(0xFF009688),
      'Cancelado' => AppColors.error,
      'Publi' => const Color(0xFF00BCD4),
      'Retirado' => const Color(0xFF795548),
      _ => AppColors.textSecondary,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'Pendente' => Icons.hourglass_top_rounded,
      'Processando' => Icons.autorenew_rounded,
      'Registrado' => Icons.assignment_rounded,
      'Agendado' => Icons.schedule_rounded,
      'Saiu pra Entrega' => Icons.local_shipping_rounded,
      'Concluído' => Icons.check_circle_rounded,
      'Cancelado' => Icons.cancel_rounded,
      'Publi' => Icons.public_rounded,
      'Retirado' => Icons.store_rounded,
      _ => Icons.help_rounded,
    };
  }

  IconData _getPaymentIcon(String? metodo) {
    return switch (metodo) {
      'Pix' => Icons.qr_code_rounded,
      'Cartão' => Icons.credit_card_rounded,
      'Crédito Site' => Icons.web_rounded,
      'V.A.' => Icons.local_atm_rounded,
      _ => Icons.payment_rounded,
    };
  }

  void _abrirDetalhes(Map<String, dynamic> data, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalhesPedido(
        data: data,
        pedidoId: id,
        onAtualizado: () => setState(() {}),
      ),
    );
  }
}

// ========================================
// DIALOG DE FILTRO DE STATUS (CHECKBOXES)
// ========================================
class _FiltroStatusDialog extends StatefulWidget {
  final Set<String> statusSelecionados;
  final Function(Set<String>) onConfirmar;

  const _FiltroStatusDialog({
    required this.statusSelecionados,
    required this.onConfirmar,
  });

  @override
  State<_FiltroStatusDialog> createState() => _FiltroStatusDialogState();
}

class _FiltroStatusDialogState extends State<_FiltroStatusDialog> {
  late Set<String> _selecionados;

  final _todosStatus = [
    'Pendente',
    'Processando',
    'Registrado',
    'Agendado',
    'Saiu pra Entrega',
    'Concluído',
    'Cancelado',
    'Publi',
    'Retirado'
  ];

  @override
  void initState() {
    super.initState();
    _selecionados = Set.from(widget.statusSelecionados);
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pendente' => AppColors.warning,
      'Processando' => AppColors.info,
      'Registrado' => const Color(0xFF9C27B0),
      'Agendado' => const Color(0xFF3F51B5),
      'Saiu pra Entrega' => AppColors.success,
      'Concluído' => const Color(0xFF009688),
      'Cancelado' => AppColors.error,
      'Publi' => const Color(0xFF00BCD4),
      'Retirado' => const Color(0xFF795548),
      _ => AppColors.textSecondary,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'Pendente' => Icons.hourglass_top_rounded,
      'Processando' => Icons.autorenew_rounded,
      'Registrado' => Icons.assignment_rounded,
      'Agendado' => Icons.schedule_rounded,
      'Saiu pra Entrega' => Icons.local_shipping_rounded,
      'Concluído' => Icons.check_circle_rounded,
      'Cancelado' => Icons.cancel_rounded,
      'Publi' => Icons.public_rounded,
      'Retirado' => Icons.store_rounded,
      _ => Icons.help_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOpacity12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Filtrar por Status', style: AppTypography.cardTitle)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione um ou mais status para filtrar',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),
            // BOTÕES: SELECIONAR TODOS / LIMPAR
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selecionados = Set.from(_todosStatus)),
                    icon: Icon(Icons.check_box_rounded, size: 18, color: AppColors.primary),
                    label: Text('Selecionar Todos', style: AppTypography.bodySmall),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selecionados.clear()),
                    icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.error),
                    label: Text('Limpar', style: AppTypography.bodySmall),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // LISTA DE CHECKBOXES
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  children: _todosStatus.map((status) {
                    final color = _getStatusColor(status);
                    final icon = _getStatusIcon(status);
                    final isSelected = _selecionados.contains(status);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selecionados.remove(status);
                          } else {
                            _selecionados.add(status);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.08) : AppColors.bgPrimary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color.withOpacity(0.3) : AppColors.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? color : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? color : AppColors.borderMedium,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(icon, size: 16, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? color : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // RESUMO E AÇÕES
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOpacity8,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryOpacity25),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_selecionados.length} status selecionado${_selecionados.length != 1 ? 's' : ''}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Aplicar',
                    onPressed: () {
                      widget.onConfirmar(_selecionados);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// MODAL DE DETALHES DO PEDIDO
// ========================================
class _DetalhesPedido extends StatefulWidget {
  final Map<String, dynamic> data;
  final String pedidoId;
  final VoidCallback onAtualizado;

  const _DetalhesPedido({
    required this.data,
    required this.pedidoId,
    required this.onAtualizado,
  });

  @override
  State<_DetalhesPedido> createState() => _DetalhesPedidoState();
}

class _DetalhesPedidoState extends State<_DetalhesPedido> {
  late List<Map<String, dynamic>> formas;
  String? entregadorSelecionado;
  late final double valorTotal;
  late final double taxa;
  List<String> _entregadores = [];
  bool _loadingEntregadores = true;

  @override
  void initState() {
    super.initState();
    final pagamento = widget.data['pagamento'] as Map<String, dynamic>?;
    formas = (pagamento?['formas'] as List?)?.cast<Map<String, dynamic>>() ?? [
      {
        'tipo': pagamento?['metodo_principal'] ?? 'Cartão',
        'valor': pagamento?['valor_total'] ?? 0.0
      }
    ];

    valorTotal = (pagamento?['valor_total'] as num?)?.toDouble() ?? 0.0;
    taxa = (pagamento?['taxa_entrega'] as num?)?.toDouble() ?? 0.0;
    
    final entregadorAtual = widget.data['entregador'];
    entregadorSelecionado = (entregadorAtual == '-' || entregadorAtual == null) ? null : entregadorAtual;

    _carregarEntregadores();
     // Teste direto
FirebaseFirestore.instance.collection('entregadores').get().then((snapshot) {
  debugPrint('🔥 Total docs: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    debugPrint('📄 Doc ID: ${doc.id}, Data: ${doc.data()}');
  }
}).catchError((e) {
  debugPrint('❌ Erro: $e');
});
  }

  

  Future<void> _carregarEntregadores() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('entregadores').get();
    setState(() {
      _entregadores = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Tenta diferentes variações do campo
        return (data['nome'] ?? data['Nome'] ?? data['NOME'] ?? 'Sem nome') as String;
      }).toList();
      _loadingEntregadores = false;
    });
  } catch (e) {
    debugPrint('Erro ao carregar entregadores: $e');
    setState(() => _loadingEntregadores = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] == '-' ? 'Processando' : (widget.data['status'] ?? 'Processando');
    final color = _getStatusColor(status);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedido #${widget.data['id']}', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        // BADGE COLORIDO
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getStatusIcon(status), size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // CONTEÚDO
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildSection(
                    title: 'Informações do Cliente',
                    icon: Icons.person_rounded,
                    children: [
                      _infoRow(Icons.badge_rounded, 'Nome', widget.data['cliente']?['nome']),
                      _infoRow(Icons.phone_rounded, 'Telefone', widget.data['cliente']?['telefone']),
                      _infoRow(Icons.location_on_rounded, 'Bairro', widget.data['endereco']?['bairro']),
                      _infoRow(Icons.home_rounded, 'Endereço', widget.data['endereco']?['logradouro']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Informações do Pedido',
                    icon: Icons.shopping_bag_rounded,
                    children: [
                      _infoRow(Icons.warehouse_rounded, 'CD', widget.data['cd']),
                      _buildEntregadorRow(),
                      if (widget.data['agendamento']?['is_agendado'] == true)
                        _infoRow(Icons.schedule_rounded, 'Agendamento', widget.data['agendamento']?['janela_texto']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Itens do Pedido',
                    icon: Icons.list_alt_rounded,
                    children: [
                      ...(widget.data['itens'] as List).map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_basket_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(item['nome'], style: AppTypography.bodySmall),
                                ),
                                Text(
                                  'Qtd: ${item['quantidade']}',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPagamentoSection(valorTotal, taxa),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // SELEÇÃO DE ENTREGADOR (DROPDOWN FUNCIONAL)
  // ========================================
  Widget _buildEntregadorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.motorcycle_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Entregador:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: _loadingEntregadores
                ? Text('Carregando...', style: AppTypography.bodySmall)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOpacity8,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryOpacity25),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: entregadorSelecionado,
                        isExpanded: true,
                        isDense: true,
                        hint: Text('Selecione um entregador', style: AppTypography.bodySmall),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem entregador'),
                          ),
                          ..._entregadores.map((nome) => DropdownMenuItem<String?>(
                                value: nome,
                                child: Text(nome, style: AppTypography.bodySmall),
                              )),
                        ],
                        onChanged: (novoEntregador) async {
                          setState(() => entregadorSelecionado = novoEntregador);

                          // ATUALIZA NO FIRESTORE
                          try {
                            await FirebaseFirestore.instance
                                .collection('pedidos')
                                .doc(widget.pedidoId)
                                .update({
                              'entregador': novoEntregador ?? '-',
                              'updated_at': FieldValue.serverTimestamp(),
                            });

                            widget.onAtualizado();

                            if (mounted) {
                              AppSnackbar.show(
                                context,
                                message: 'Entregador atualizado com sucesso!',
                                type: AppSnackbarType.success,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackbar.show(
                                context,
                                message: 'Erro ao atualizar entregador: $e',
                                type: AppSnackbarType.error,
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPagamentoSection(double valorTotal, double taxa) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payment_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Formas de Pagamento', style: AppTypography.label),
                ],
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                onPressed: _editarPagamentos,
                tooltip: 'Editar Pagamento',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...formas.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_getIconForma(f['tipo']), size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f['tipo'],
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      'R\$ ${(f['valor'] as num).toStringAsFixed(2)}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
          _infoRow(Icons.delivery_dining_rounded, 'Taxa de Entrega', 'R\$ ${taxa.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _infoRow(
            Icons.paid_rounded,
            'TOTAL',
            'R\$ ${valorTotal.toStringAsFixed(2)}',
            isBold: true,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  void _editarPagamentos() {
    showDialog(
      context: context,
      builder: (_) => _PagamentoDialog(
        formasIniciais: List.from(formas),
        valorTotal: valorTotal,
        onSalvar: (novasFormas) async {
          await FirebaseFirestore.instance.collection('pedidos').doc(widget.pedidoId).update({
            'pagamento.formas': novasFormas,
            'updated_at': FieldValue.serverTimestamp(),
          });
          setState(() => formas = novasFormas);
          widget.onAtualizado();
          Navigator.pop(context);
          AppSnackbar.show(
            context,
            message: 'Pagamento atualizado com sucesso!',
            type: AppSnackbarType.success,
          );
        },
      ),
    );
  }

  IconData _getIconForma(String tipo) {
    return switch (tipo) {
      'Cartão' => Icons.credit_card_rounded,
      'Pix' => Icons.qr_code_rounded,
      'Crédito Site' => Icons.web_rounded,
      'V.A.' => Icons.local_atm_rounded,
      _ => Icons.payment_rounded,
    };
  }

  Widget _infoRow(IconData icon, String label, dynamic value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pendente' => AppColors.warning,
      'Processando' => AppColors.info,
      'Registrado' => const Color(0xFF9C27B0),
      'Agendado' => const Color(0xFF3F51B5),
      'Saiu pra Entrega' => AppColors.success,
      'Concluído' => const Color(0xFF009688),
      'Cancelado' => AppColors.error,
      'Publi' => const Color(0xFF00BCD4),
      'Retirado' => const Color(0xFF795548),
      _ => AppColors.textSecondary,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'Pendente' => Icons.hourglass_top_rounded,
      'Processando' => Icons.autorenew_rounded,
      'Registrado' => Icons.assignment_rounded,
      'Agendado' => Icons.schedule_rounded,
      'Saiu pra Entrega' => Icons.local_shipping_rounded,
      'Concluído' => Icons.check_circle_rounded,
      'Cancelado' => Icons.cancel_rounded,
      'Publi' => Icons.public_rounded,
      'Retirado' => Icons.store_rounded,
      _ => Icons.help_rounded,
    };
  }
}

// ========================================
// DIALOG DE EDIÇÃO DE PAGAMENTO
// ========================================
class _PagamentoDialog extends StatefulWidget {
  final List<Map<String, dynamic>> formasIniciais;
  final double valorTotal;
  final Function(List<Map<String, dynamic>>) onSalvar;

  const _PagamentoDialog({
    required this.formasIniciais,
    required this.valorTotal,
    required this.onSalvar,
  });

  @override
  State<_PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<_PagamentoDialog> {
  late List<Map<String, dynamic>> formas;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {

    super.initState();
    formas = widget.formasIniciais.map((f) => Map<String, dynamic>.from(f)).toList();
    
    for (var forma in formas) {
      final controller = TextEditingController(text: forma['valor'].toString());
      controller.addListener(() {
        final valor = double.tryParse(controller.text) ?? 0.0;
        forma['valor'] = valor;
        setState(() {});
      });
      _controllers.add(controller);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get totalPago => formas.fold(0.0, (sum, f) => sum + (f['valor'] as num).toDouble());
  bool get isValid => (totalPago - widget.valorTotal).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOpacity12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Editar Pagamento', style: AppTypography.cardTitle)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...formas.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: DropdownButton<String>(
                            value: f['tipo'],
                            items: ['Cartão', 'Pix', 'Crédito Site', 'V.A.']
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t, style: AppTypography.bodySmall),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => f['tipo'] = v),
                            underline: const SizedBox.shrink(),
                            isExpanded: true,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _controllers[i],
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodySmall,
                          decoration: InputDecoration(
                            prefixText: 'R\$ ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      if (formas.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                          onPressed: () {
                            setState(() {
                              _controllers[i].dispose();
                              _controllers.removeAt(i);
                              formas.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                ),
              );
            }),
            AppButton(
              label: 'Adicionar Forma de Pagamento',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outline,
              fullWidth: true,
              size: AppButtonSize.small,
              onPressed: () {
                setState(() {
                  formas.add({'tipo': 'Pix', 'valor': 0.0});
                  final controller = TextEditingController(text: '0.0');
                  controller.addListener(() {
                    final valor = double.tryParse(controller.text) ?? 0.0;
                    formas.last['valor'] = valor;
                    setState(() {});
                  });
                  _controllers.add(controller);
                });
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isValid ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid ? AppColors.success.withOpacity(0.25) : AppColors.error.withOpacity(0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total pago', style: AppTypography.caption),
                      Text(
                        'R\$ ${totalPago.toStringAsFixed(2)}',
                        style: AppTypography.label.copyWith(
                          color: isValid ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total esperado', style: AppTypography.caption),
                      Text(
                        'R\$ ${widget.valorTotal.toStringAsFixed(2)}',
                        style: AppTypography.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Salvar',
                    size: AppButtonSize.medium,
                    onPressed: isValid ? () => widget.onSalvar(formas) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}