// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _periodoSelecionado = 'Hoje';
  final _periodos = ['Hoje', 'Semana', 'Mês'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.bgPrimary,
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _buildQuery().snapshots(),  // ⚠️ Adicione .snapshots() aqui!
  builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingIndicator(size: 48));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar dados', style: AppTypography.sectionTitle),
                const SizedBox(height: 8),
                Text(snapshot.error.toString(), style: AppTypography.caption),
              ],
            ),
          );
        }

        final pedidos = snapshot.data?.docs ?? [];
        final dados = _processarDados(pedidos);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMetricasRapidas(dados),
              const SizedBox(height: 24),
              // ⚠️ CORREÇÃO AQUI: Wrap com LayoutBuilder para calcular altura
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildFaturamentoChart(dados),
                                const SizedBox(height: 16),
                                _buildPedidosPorHorario(dados),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildDistribuicaoCDs(dados),
                                const SizedBox(height: 16),
                                _buildFormasPagamento(dados),
                                const SizedBox(height: 16),
                                _buildRankingEntregadores(dados),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPedidosPendentes(pedidos),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

  // ========================================
  // HEADER COM FILTRO DE PERÍODO
  // ========================================
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: AppTypography.sectionTitle),
              const SizedBox(height: 4),
              Text(
                'Visão geral do negócio em tempo real',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: _periodos.map((periodo) {
              final isSelected = _periodoSelecionado == periodo;
              return GestureDetector(
                onTap: () => setState(() => _periodoSelecionado = periodo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    periodo,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ========================================
  // MÉTRICAS RÁPIDAS (CARDS ANIMADOS)
  // ========================================
 Widget _buildMetricasRapidas(Map<String, dynamic> dados) {
  final metricas = [
    {
      'label': 'Faturamento',
      'valor': 'R\$ ${_formatarValor(dados['faturamento_total'] ?? 0)}',  // ⚠️ Adicionei ?? 0
      'icon': Icons.paid_rounded,
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
      'trend': '+12%',
      'subtitle': 'vs. período anterior',
    },
    {
      'label': 'Pedidos',
      'valor': '${dados['total_pedidos'] ?? 0}',  // ⚠️ Adicionei ?? 0
      'icon': Icons.shopping_cart_rounded,
      'color': AppColors.primary,
      'gradient': [AppColors.primary, const Color(0xFF5E35B1)],
      'trend': '+8%',
      'subtitle': '${dados['pedidos_concluidos'] ?? 0} concluídos',  // ⚠️ Adicionei ?? 0
    },
    {
      'label': 'Ticket Médio',
      'valor': 'R\$ ${_formatarValor(dados['ticket_medio'] ?? 0)}',  // ⚠️ Adicionei ?? 0
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFFF9800),
      'gradient': [const Color(0xFFFF9800), const Color(0xFFFFA726)],
      'trend': '+5%',
      'subtitle': 'por pedido',
    },
    {
      'label': 'Taxa Conclusão',
      'valor': '${dados['taxa_conclusao'] ?? 0}%',  // ⚠️ Adicionei ?? 0
      'icon': Icons.check_circle_rounded,
      'color': const Color(0xFF00BCD4),
      'gradient': [const Color(0xFF00BCD4), const Color(0xFF26C6DA)],
      'trend': '+3%',
      'subtitle': 'dos pedidos',
    },
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
    ),
    itemCount: metricas.length,
    itemBuilder: (context, index) {
      final metrica = metricas[index];
      return _buildMetricCard(
        label: metrica['label'] as String,
        valor: metrica['valor'] as String,
        icon: metrica['icon'] as IconData,
        gradient: metrica['gradient'] as List<Color>,
        trend: metrica['trend'] as String,
        subtitle: metrica['subtitle'] as String,
        delay: index * 100,
      );
    },
  );
}

  Widget _buildMetricCard({
    required String label,
    required String valor,
    required IconData icon,
    required List<Color> gradient,
    required String trend,
    required String subtitle,
    required int delay,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay / 1000, 1.0, curve: Curves.easeOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: AppTypography.cardTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // GRÁFICO DE FATURAMENTO (ÚLTIMOS 7 DIAS)
  // ========================================
  Widget _buildFaturamentoChart(Map<String, dynamic> dados) {
    final List<Map<String, dynamic>> faturamentoDiario = dados['faturamento_diario'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Faturamento Diário', style: AppTypography.label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOpacity8,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryOpacity25),
                ),
                child: Text(
                  'Últimos 7 dias',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: faturamentoDiario.isEmpty
                ? const Center(child: Text('Sem dados para exibir'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 500,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) => Text(
                              'R\$${value.toInt()}',
                              style: AppTypography.caption.copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < faturamentoDiario.length) {
                                final dia = faturamentoDiario[index]['dia'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dia,
                                    style: AppTypography.caption.copyWith(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            faturamentoDiario.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              (faturamentoDiario[index]['valor'] as num).toDouble(),
                            ),
                          ),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, const Color(0xFF5E35B1)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: AppColors.primary,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // PEDIDOS POR HORÁRIO
  // ========================================
  Widget _buildPedidosPorHorario(Map<String, dynamic> dados) {
  final List<Map<String, dynamic>> porHorario = dados['pedidos_por_horario'] ?? [];

  // Calcula o maxY com segurança de tipo
  double maxY = 10.0; // valor padrão
  if (porHorario.isNotEmpty) {
    final maxQuantidade = porHorario
        .map((e) => (e['quantidade'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);
    maxY = maxQuantidade + 5.0;
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Pedidos por Horário', style: AppTypography.label),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: porHorario.isEmpty
              ? const Center(child: Text('Sem dados'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: AppTypography.caption.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < porHorario.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  porHorario[index]['horario'] as String,
                                  style: AppTypography.caption.copyWith(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.borderLight,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      porHorario.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (porHorario[index]['quantidade'] as int).toDouble(),
                            gradient: LinearGradient(
                              colors: [const Color(0xFF00BCD4), const Color(0xFF26C6DA)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ),
  );
}

  // ========================================
  // DISTRIBUIÇÃO POR CDs (DONUT CHART)
  // ========================================
  Widget _buildDistribuicaoCDs(Map<String, dynamic> dados) {
    final Map<String, int> porCD = Map<String, int>.from(dados['pedidos_por_cd'] ?? {});
    final total = porCD.values.fold(0, (sum, val) => sum + val);

    final cores = {
      'CD Central': AppColors.primary,
      'CD Sion': const Color(0xFFFF9800),
      'CD Barreiro': const Color(0xFF4CAF50),
      'CD Lagoa Santa': const Color(0xFF00BCD4),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Pedidos por CD', style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 24),
          if (porCD.isEmpty)
            const Center(child: Text('Sem dados'))
          else
            Column(
              children: [
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sections: porCD.entries.map((entry) {
                        final porcentagem = (entry.value / total * 100).toStringAsFixed(0);
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '$porcentagem%',
                          color: cores[entry.key] ?? AppColors.textSecondary,
                          radius: 50,
                          titleStyle: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...porCD.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cores[entry.key],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
        ],
      ),
    );
  }

  // ========================================
  // FORMAS DE PAGAMENTO
  // ========================================
  Widget _buildFormasPagamento(Map<String, dynamic> dados) {
    final Map<String, int> formas = Map<String, int>.from(dados['formas_pagamento'] ?? {});

    final icones = {
      'Pix': Icons.qr_code_rounded,
      'Cartão': Icons.credit_card_rounded,
      'Crédito Site': Icons.web_rounded,
      'V.A.': Icons.local_atm_rounded,
    };

    final cores = {
      'Pix': const Color(0xFF00BCD4),
      'Cartão': AppColors.primary,
      'Crédito Site': const Color(0xFFFF9800),
      'V.A.': const Color(0xFF4CAF50),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Formas de Pagamento', style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 16),
          if (formas.isEmpty)
            const Center(child: Text('Sem dados'))
          else
            ...formas.entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (cores[entry.key] ?? AppColors.textSecondary).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (cores[entry.key] ?? AppColors.textSecondary).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icones[entry.key] ?? Icons.payment_rounded,
                        color: cores[entry.key] ?? AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cores[entry.key] ?? AppColors.textSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ========================================
  // RANKING DE ENTREGADORES
  // ========================================
  Widget _buildRankingEntregadores(Map<String, dynamic> dados) {
    final List<Map<String, dynamic>> ranking = dados['ranking_entregadores'] ?? [];

    final medalhas = [
      const Color(0xFFFFD700), // Ouro
      const Color(0xFFC0C0C0), // Prata
      const Color(0xFFCD7F32), // Bronze
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Top Entregadores', style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 16),
          if (ranking.isEmpty)
            const Center(child: Text('Sem dados'))
          else
            ...ranking.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final entregador = entry.value;
              final isMedalhista = index < 3;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMedalhista ? medalhas[index].withOpacity(0.08) : AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMedalhista ? medalhas[index].withOpacity(0.3) : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isMedalhista ? medalhas[index] : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isMedalhista
                            ? Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18)
                            : Text(
                                '${index + 1}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entregador['nome'] as String,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${entregador['entregas']} entregas',
                            style: AppTypography.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.motorcycle_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ========================================
  // PEDIDOS PENDENTES (AÇÕES RÁPIDAS)
  // ========================================
  Widget _buildPedidosPendentes(List<QueryDocumentSnapshot> pedidos) {
    final pendentes = pedidos.where((p) {
      final data = p.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';
      return ['Pendente', 'Processando', 'Registrado'].contains(status);
    }).take(5).toList();

    if (pendentes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text('Pedidos Pendentes', style: AppTypography.label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  '${pendentes.length} ativo${pendentes.length > 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pendentes.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Pendente';
            final statusColor = _getStatusColor(status);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${data['id']}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['cliente']?['nome'] ?? 'Cliente',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          data['endereco']?['bairro'] ?? 'Sem bairro',
                          style: AppTypography.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ========================================
  // HELPERS
  // ========================================
  Query<Map<String, dynamic>> _buildQuery() {
  return FirebaseFirestore.instance
      .collection('pedidos')
      .where('is_ativo', isEqualTo: true)
      .limit(100); // Limita a 100 pedidos para não sobrecarregar
}

  

  Map<String, dynamic> _processarDados(List<QueryDocumentSnapshot> docs) {
  final now = DateTime.now();
  DateTime startDate;

  // Define o período
  switch (_periodoSelecionado) {
    case 'Hoje':
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case 'Semana':
      startDate = now.subtract(const Duration(days: 7));
      break;
    case 'Mês':
      startDate = DateTime(now.year, now.month, 1);
      break;
    default:
      startDate = DateTime(now.year, now.month, now.day);
  }

  // FILTRA OS DOCUMENTOS POR PERÍODO AQUI
  final docsFiltrados = docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final agendamento = data['agendamento'] as Map<String, dynamic>?;
    final dataAgendamento = agendamento?['data'] as Timestamp?;
    
    if (dataAgendamento == null) return false;
    
    return dataAgendamento.toDate().isAfter(startDate);
  }).toList();

  // Resto do processamento igual, mas usando docsFiltrados
  double faturamentoTotal = 0;
  int totalPedidos = docsFiltrados.length;
  int pedidosConcluidos = 0;
  Map<String, int> porCD = {};
  Map<String, int> formasPagamento = {};
  Map<String, int> porEntregador = {};
  Map<int, int> porHorario = {};
  List<Map<String, dynamic>> faturamentoDiario = [];

  final porDia = <String, double>{};

  for (var doc in docsFiltrados) {
    final data = doc.data() as Map<String, dynamic>;
    final pagamento = data['pagamento'] as Map<String, dynamic>?;
    final status = data['status'] ?? '';
    final cd = data['cd'] ?? 'Sem CD';
    final entregador = data['entregador'] ?? '';
    final agendamento = data['agendamento'] as Map<String, dynamic>?;

    final valor = (pagamento?['valor_total'] as num?)?.toDouble() ?? 0;
    faturamentoTotal += valor;

    if (status == 'Concluído') pedidosConcluidos++;

    porCD[cd] = (porCD[cd] ?? 0) + 1;

    final forma = pagamento?['metodo_principal'] ?? 'Não informado';
    formasPagamento[forma] = (formasPagamento[forma] ?? 0) + 1;

    if (entregador != '-' && entregador.isNotEmpty) {
      porEntregador[entregador] = (porEntregador[entregador] ?? 0) + 1;
    }

    final dataAgendamento = agendamento?['data'] as Timestamp?;
    if (dataAgendamento != null) {
      final hora = dataAgendamento.toDate().hour;
      porHorario[hora] = (porHorario[hora] ?? 0) + 1;

      final dia = DateFormat('dd/MM').format(dataAgendamento.toDate());
      porDia[dia] = (porDia[dia] ?? 0) + valor;
    }
  }

  // Faturamento diário (últimos 7 dias)
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dia = DateFormat('dd/MM').format(date);
    faturamentoDiario.add({
      'dia': DateFormat('EEE').format(date),
      'valor': porDia[dia] ?? 0.0,
    });
  }

  // Pedidos por horário
  final pedidosPorHorario = <Map<String, dynamic>>[];
  final horarios = ['Manhã', 'Tarde', 'Noite'];
  final ranges = [[6, 12], [12, 18], [18, 24]];

  for (int i = 0; i < horarios.length; i++) {
    int total = 0;
    for (int hora = ranges[i][0]; hora < ranges[i][1]; hora++) {
      total += porHorario[hora] ?? 0;
    }
    pedidosPorHorario.add({'horario': horarios[i], 'quantidade': total});
  }

  // Ranking entregadores
  final rankingEntregadores = porEntregador.entries.map((e) => {
        'nome': e.key,
        'entregas': e.value,
      }).toList()
    ..sort((a, b) => (b['entregas'] as int).compareTo(a['entregas'] as int));

  final ticketMedio = totalPedidos > 0 ? faturamentoTotal / totalPedidos : 0;
  final taxaConclusao = totalPedidos > 0 ? (pedidosConcluidos / totalPedidos * 100).toInt() : 0;

  return {
    'faturamento_total': faturamentoTotal,
    'total_pedidos': totalPedidos,
    'pedidos_concluidos': pedidosConcluidos,
    'ticket_medio': ticketMedio,
    'taxa_conclusao': taxaConclusao,
    'pedidos_por_cd': porCD,
    'formas_pagamento': formasPagamento,
    'ranking_entregadores': rankingEntregadores,
    'pedidos_por_horario': pedidosPorHorario,
    'faturamento_diario': faturamentoDiario,
  };
}

  String _formatarValor(num valor) {  // ⚠️ Mudei de double para num
  final valorDouble = valor.toDouble();
  if (valorDouble >= 1000) {
    return '${(valorDouble / 1000).toStringAsFixed(1)}k';
  }
  return valorDouble.toStringAsFixed(0);
}

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pendente' => AppColors.warning,
      'Processando' => AppColors.info,
      'Registrado' => const Color(0xFF9C27B0),
      _ => AppColors.textSecondary,
    };
  }
}