// lib/pages/pedidos_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../design_system.dart';

// URL DO GOOGLE APPS SCRIPT (substitua pela sua URL de deploy)
const String GOOGLE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbwZuFyCgoLU_oTUc98ayUDFnR4aGwIYTzDGWOoJT99elnUdN6sp1s_tm5r7gaQol1lb/exec';

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);
  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _cdFiltro = 'CD Central';
  DateTime? _dataInicial;
  DateTime? _dataFinal;
  String _busca = '';
  Set<String> _statusFiltros = {};

  final _cds = ['CD Central', 'CD Sion', 'CD Barreiro', 'CD Lagoa Santa', 'Todos'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _busca = _searchController.text.toLowerCase()));
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

  Widget _buildHeaderCompacto() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
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
        final saiuEntrega = docs.where((d) {
          final status = (d.data() as Map)['status'] ?? '';
          return status == 'Saiu pra Entrega';
        }).length;
        final concluidos = docs.where((d) {
          final status = (d.data() as Map)['status'] ?? '';
          return status == 'Concluído';
        }).length;

        return Row(
          children: [
            _buildStatMini('Total', total.toString(), AppColors.primary, Icons.shopping_cart_rounded),
            const SizedBox(width: 12),
            _buildStatMini('Saiu pra Entrega', saiuEntrega.toString(), const Color(0xFF4CAF50), Icons.local_shipping_rounded),
            const SizedBox(width: 12),
            _buildStatMini('Concluídos', concluidos.toString(), const Color(0xFF009688), Icons.check_circle_rounded),
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

  Widget _buildFiltrosCompactos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Column(
        children: [
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
          Row(
            children: [
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
              Expanded(
                flex: 2,
                child: _buildFilterButton(
                  icon: Icons.calendar_today_rounded,
                  label: _dataInicial == null ? 'Data inicial' : DateFormat('dd/MM/yy').format(_dataInicial!),
                  onTap: () => _selecionarData(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildFilterButton(
                  icon: Icons.event_rounded,
                  label: _dataFinal == null ? 'Data final' : DateFormat('dd/MM/yy').format(_dataFinal!),
                  onTap: () => _selecionarData(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildStatusDropdown(),
              ),
              const SizedBox(width: 8),
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

  Widget _buildStatusDropdown() {
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

    return PopupMenuButton<String>(
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
            Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusFiltros.isEmpty 
                    ? 'Todos os status' 
                    : '${_statusFiltros.length} selecionado${_statusFiltros.length > 1 ? 's' : ''}',
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtrar por Status', style: AppTypography.label),
                  TextButton(
                    onPressed: () {
                      setState(() => _statusFiltros.clear());
                      Navigator.pop(context);
                    },
                    child: Text('Limpar', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
              const Divider(height: 8),
            ],
          ),
        ),
        ..._todosStatus.map((status) {
          final isSelected = _statusFiltros.contains(status);
          final color = _getStatusColor(status);
          
          return PopupMenuItem<String>(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: StatefulBuilder(
              builder: (context, setStateMenu) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (_statusFiltros.contains(status)) {
                        _statusFiltros.remove(status);
                      } else {
                        _statusFiltros.add(status);
                      }
                    });
                    setStateMenu(() {});
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSelected ? color : AppColors.borderMedium, width: 2),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 12),
                      Icon(_getStatusIcon(status), size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(status, style: AppTypography.bodySmall)),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
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
                child: Text(label, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
              )
            else if (child != null)
              Expanded(child: child),
          ],
        ),
      ),
    );
  }

  DateTime? _extrairHoraInicial(String slot) {
  // Ex: "09:00 - 12:00" → pega "09:00"
  final match = RegExp(r'(\d{2}:\d{2})').firstMatch(slot);
  if (match == null) return null;

  final hora = match.group(1)!;
  try {
    final hoje = DateTime.now();
    final partes = hora.split(':');
    return DateTime(hoje.year, hoje.month, hoje.day, int.parse(partes[0]), int.parse(partes[1]));
  } catch (e) {
    return null;
  }
}

  Future<void> _selecionarData(bool isInicial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isInicial ? (_dataInicial ?? DateTime.now()) : (_dataFinal ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
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

      // === ORDENAÇÃO NO CLIENTE ===
      filtered.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        // 1. created_at (mais novo no topo)
        final createdA = (dataA['created_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        final createdB = (dataB['created_at'] as Timestamp?)?.toDate() ?? DateTime(0);
        final compareCreated = createdB.compareTo(createdA);
        if (compareCreated != 0) return compareCreated;

        // 2. slot de agendamento
        final slotA = (dataA['agendamento']?['janela_texto'] ?? '').toString();
        final slotB = (dataB['agendamento']?['janela_texto'] ?? '').toString();
        final horaA = _extrairHoraInicial(slotA);
        final horaB = _extrairHoraInicial(slotB);

        if (horaA == null && horaB == null) return 0;
        if (horaA == null) return 1;
        if (horaB == null) return -1;
        return horaA.compareTo(horaB);
      });

      // === ESTADO VAZIO ===
      if (filtered.isEmpty) {
        return AppEmptyState(
          icon: Icons.inbox_rounded,
          title: 'Nenhum pedido encontrado',
          message: _busca.isNotEmpty || _statusFiltros.isNotEmpty
              ? 'Tente ajustar os filtros para encontrar o que procura'
              : 'Ainda não há pedidos registrados para este período',
        );
      }

      // === LISTA DE PEDIDOS ===
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

  // === FILTRO DE CD (com tratamento de cd vazio) ===
  if (_cdFiltro == 'Todos') {
    // sem filtro
  } else if (_cdFiltro == 'CD Central') {
    query = query.where('cd', whereIn: ['CD Central', '']);
  } else {
    query = query.where('cd', isEqualTo: _cdFiltro);
  }

  // === FILTRO DE DATA (agendamento) ===
  if (_dataInicial != null || _dataFinal != null) {
    query = query.orderBy('agendamento.data', descending: true);
    if (_dataInicial != null) {
      query = query.where('agendamento.data', isGreaterThanOrEqualTo: _dataInicial);
    }
    if (_dataFinal != null) {
      query = query.where('agendamento.data', isLessThanOrEqualTo: _dataFinal);
    }
  }

  // === ORDENAÇÃO PRINCIPAL: created_at (desc) ===
  query = query.orderBy('created_at', descending: true);

  // === ORDENAÇÃO SECUNDÁRIA: slot de agendamento (cronológico) ===
  // Vamos ordenar por hora inicial do slot (ex: "09:00")
  // Mas como é string, vamos extrair no cliente
  // → Não dá pra ordenar por substring no Firestore

  return query;
}

  // CARD COM BADGE DE TIPO DE ENTREGA
  Widget _buildPedidoCard(Map<String, dynamic> data, String id) {
    final status = data['status'] == '-' ? 'Processando' : (data['status'] ?? 'Processando');
    final color = _getStatusColor(status);
    final tipoEntrega = data['tipo_entrega']?.toString() ?? 'delivery';

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    const SizedBox(width: 8),
                    // BADGE DE TIPO DE ENTREGA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tipoEntrega == 'delivery' 
                            ? const Color(0xFF2196F3).withOpacity(0.15)
                            : const Color(0xFFFF9800).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tipoEntrega == 'delivery' 
                              ? const Color(0xFF2196F3).withOpacity(0.3)
                              : const Color(0xFFFF9800).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tipoEntrega == 'delivery' ? Icons.delivery_dining_rounded : Icons.store_rounded,
                            size: 14,
                            color: tipoEntrega == 'delivery' ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tipoEntrega == 'delivery' ? 'Entrega' : 'Retirada',
                            style: AppTypography.labelSmall.copyWith(
                              color: tipoEntrega == 'delivery' ? const Color(0xFF2196F3) : const Color(0xFFFF9800),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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
                          Icon(_getStatusIcon(status), size: 13, color: Colors.white),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cliente?['nome'] ?? 'Cliente',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOpacity12,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryOpacity25),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(bairro, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              slot,
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(_getPaymentIcon(pagamento?['metodo_principal']), size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              pagamento?['metodo_principal'] ?? 'Pagamento',
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.motorcycle_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              entregador,
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
  String? statusSelecionado;
  late double valorTotal;
  late double taxa;
  List<String> _entregadores = [];
  bool _loadingEntregadores = true;

  @override
  void initState() {
    super.initState();
    final statusAtual = widget.data['status'] == '-' ? 'Processando' : (widget.data['status'] ?? 'Processando');
  statusSelecionado = statusAtual;
    final pagamento = widget.data['pagamento'] as Map<String, dynamic>?;
    formas = (pagamento?['formas'] as List?)?.cast<Map<String, dynamic>>() ?? [
      {'tipo': pagamento?['metodo_principal'] ?? 'Cartão', 'valor': pagamento?['valor_total'] ?? 0.0}
    ];

    valorTotal = (pagamento?['valor_total'] as num?)?.toDouble() ?? 0.0;
    taxa = (pagamento?['taxa_entrega'] as num?)?.toDouble() ?? 0.0;
    
    final entregadorAtual = widget.data['entregador'];
    entregadorSelecionado = (entregadorAtual == '-' || entregadorAtual == null) ? null : entregadorAtual;

    _carregarEntregadores();
  }

  Future<void> _carregarEntregadores() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('entregadores').get();
      setState(() {
        _entregadores = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
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
                      _buildStatusRow(),
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
                                Expanded(child: Text(item['nome'], style: AppTypography.bodySmall)),
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
                  _buildPagamentoSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                          const DropdownMenuItem<String?>(value: null, child: Text('Sem entregador')),
                          ..._entregadores.map((nome) => DropdownMenuItem<String?>(
                                value: nome,
                                child: Text(nome, style: AppTypography.bodySmall),
                              )),
                        ],
                        onChanged: (novoEntregador) async {
                          setState(() => entregadorSelecionado = novoEntregador);

                          try {
                            // Atualiza no Firestore
                            await FirebaseFirestore.instance.collection('pedidos').doc(widget.pedidoId).update({
                              'entregador': novoEntregador ?? '-',
                              'updated_at': FieldValue.serverTimestamp(),
                            });

                            // Sincroniza com Google Sheets
                            await _sincronizarComSheets(
                              id: widget.data['id'],
                              cd: widget.data['cd'],
                              status: widget.data['status'],
                              entregador: novoEntregador ?? '-',
                            );

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

  Widget _buildStatusRow() {
  final statusList = [
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

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sync_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Status:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryOpacity8,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryOpacity25),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusSelecionado,
                isExpanded: true,
                isDense: true,
                hint: Text('Selecione o status', style: AppTypography.bodySmall),
                items: statusList.map((s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(s), size: 16, color: _getStatusColor(s)),
                      const SizedBox(width: 6),
                      Text(s, style: AppTypography.bodySmall),
                    ],
                  ),
                )).toList(),
                onChanged: (novoStatus) async {
                  if (novoStatus == null) return;

                  setState(() => statusSelecionado = novoStatus);

                  try {
                    await FirebaseFirestore.instance
                        .collection('pedidos')
                        .doc(widget.pedidoId)
                        .update({
                      'status': novoStatus == 'Processando' ? '-' : novoStatus,
                      'updated_at': FieldValue.serverTimestamp(),
                    });

                    await _sincronizarComSheets(
                      id: widget.data['id'],
                      cd: widget.data['cd'],
                      status: novoStatus,
                    );

                    widget.onAtualizado();
                    AppSnackbar.show(
                      context,
                      message: 'Status atualizado para: $novoStatus',
                      type: AppSnackbarType.success,
                    );
                  } catch (e) {
                    setState(() => statusSelecionado = widget.data['status'] == '-' ? 'Processando' : widget.data['status']);
                    AppSnackbar.show(
                      context,
                      message: 'Erro ao atualizar status: $e',
                      type: AppSnackbarType.error,
                    );
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

  Widget _buildPagamentoSection() {
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
                  Text('Pagamento', style: AppTypography.label),
                ],
              ),
              AppIconButton(
                icon: Icons.edit_rounded,
                tooltip: 'Editar Pagamento',
                size: 16,
                onPressed: _editarPagamento,
              ),
            ],
          ),
          const Divider(height: 20),
          ...formas.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_getIconForma(f['tipo']), size: 16, color: AppColors.textSecondary),
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
          Row(
            children: [
              Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Taxa de Entrega')),
              Text(
                'R\$ ${taxa.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.paid_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TOTAL',
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'R\$ ${valorTotal.toStringAsFixed(2)}',
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editarPagamento() {
    showDialog(
      context: context,
      builder: (_) => _PagamentoDialog(
        formasIniciais: List.from(formas),
        valorTotalInicial: valorTotal,
        taxaInicial: taxa,
        onSalvar: (novasFormas, novoTotal, novaTaxa) async {
          try {
            // Atualiza no Firestore
            await FirebaseFirestore.instance.collection('pedidos').doc(widget.pedidoId).update({
              'pagamento.formas': novasFormas,
              'pagamento.valor_total': novoTotal,
              'pagamento.taxa_entrega': novaTaxa,
              'updated_at': FieldValue.serverTimestamp(),
            });

            // Sincroniza com Google Sheets
            await _sincronizarComSheets(
              id: widget.data['id'],
              cd: widget.data['cd'],
              status: widget.data['status'],
              formasPagamento: novasFormas,
              valorTotal: novoTotal,
              taxaEntrega: novaTaxa,
            );

            setState(() {
              formas = novasFormas;
              valorTotal = novoTotal;
              taxa = novaTaxa;
            });
            widget.onAtualizado();
            Navigator.pop(context);
            AppSnackbar.show(
              context,
              message: 'Pagamento atualizado com sucesso!',
              type: AppSnackbarType.success,
            );
          } catch (e) {
            AppSnackbar.show(
              context,
              message: 'Erro ao atualizar pagamento: $e',
              type: AppSnackbarType.error,
            );
          }
        },
      ),
    );
  }

  // INTEGRAÇÃO COM GOOGLE SHEETS
  Future<void> _sincronizarComSheets({
    required String id,
    required String cd,
    required String status,
    String? entregador,
    List<Map<String, dynamic>>? formasPagamento,
    double? valorTotal,
    double? taxaEntrega,
  }) async {
    try {
      // Monta o payload
      final payload = {
        'action': 'UpdatePedido',
        'id': id,
        'cd': cd,
        'status': status,
      };

      if (entregador != null) {
        payload['entregador'] = entregador;
      }

      if (formasPagamento != null && formasPagamento.isNotEmpty) {
        // Concatena formas de pagamento (ex: "Cartão + Pix")
        final formasTexto = formasPagamento.map((f) => f['tipo']).join(' + ');
        payload['pagamento'] = formasTexto;
      }

      if (valorTotal != null) {
        payload['valor_total'] = valorTotal.toString();
      }

      if (taxaEntrega != null) {
        payload['taxa_entrega'] = taxaEntrega.toString();
      }

      // Faz o fetch para o Google Apps Script
      final response = await http.get(
        Uri.parse(GOOGLE_SCRIPT_URL).replace(queryParameters: payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] != 'success') {
          debugPrint('Erro ao sincronizar com Sheets: ${result['message']}');
        }
      } else {
        debugPrint('Erro HTTP ao sincronizar com Sheets: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar com Sheets: $e');
    }
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

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: AppTypography.bodySmall,
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
  final double valorTotalInicial;
  final double taxaInicial;
  final Function(List<Map<String, dynamic>>, double, double) onSalvar;

  const _PagamentoDialog({
    required this.formasIniciais,
    required this.valorTotalInicial,
    required this.taxaInicial,
    required this.onSalvar,
  });

  @override
  State<_PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<_PagamentoDialog> {
  late List<Map<String, dynamic>> formas;
  final List<TextEditingController> _controllers = [];
  late TextEditingController _taxaController;
  late TextEditingController _totalController;

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

    _taxaController = TextEditingController(text: widget.taxaInicial.toStringAsFixed(2));
    _totalController = TextEditingController(text: widget.valorTotalInicial.toStringAsFixed(2));
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _taxaController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  double get totalPago => formas.fold(0.0, (sum, f) => sum + (f['valor'] as num).toDouble());
  double get valorTotal => double.tryParse(_totalController.text) ?? 0.0;
  double get taxa => double.tryParse(_taxaController.text) ?? 0.0;
  bool get isValid => (totalPago - valorTotal).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
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
            Text('Formas de Pagamento', style: AppTypography.label),
            const SizedBox(height: 12),
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
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.bodySmall)))
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
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text('Valores', style: AppTypography.label),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Taxa de Entrega',
                    controller: _taxaController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.delivery_dining_rounded,
                    onSuffixTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Valor Total',
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.paid_rounded,
                    onSuffixTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid ? AppColors.success : AppColors.error,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Valor total', style: AppTypography.caption),
                      Text(
                        'R\$ ${valorTotal.toStringAsFixed(2)}',
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Salvar',
                    onPressed: isValid ? () => widget.onSalvar(formas, valorTotal, taxa) : null,
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