// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gas_api.dart';
import '../globals.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Color primaryColor = const Color(0xFFF28C38);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String today = DateFormat('dd-MM').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: FutureBuilder<List<Pedido>>(
            future: GasApi.readPedidos(onlyUnprinted: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF28C38)),
                    strokeWidth: 4.0,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Nenhum pedido encontrado.'));
              }

              final pedidos = snapshot.data!;
              final pedidosDoDia = _filtrarPedidosDoDia(pedidos, today);

              if (pedidosDoDia.isEmpty) {
                return const Center(child: Text('Nenhum pedido agendado para hoje.'));
              }

              final pedidosValidos = pedidosDoDia.where((p) =>
                !['cancelado', 'Cancelado'].contains(p.status?.trim())
              ).toList();

              final totalValue = _calcularTotal(pedidosValidos);
              final totalOrders = pedidosValidos.length;
              final slots = _contarPorSlot(pedidosValidos);
              final statusCount = _contarStatus(pedidosValidos);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsCard(totalValue, totalOrders),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _buildStatusCard(statusCount, totalOrders),
                        _buildPedidosPorSlotCard(slots),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Pedido> _filtrarPedidosDoDia(List<Pedido> pedidos, String today) {
    return pedidos.where((p) {
      final dataRaw = p.dataAgendamento ?? p.data ?? '';
      if (dataRaw.isEmpty) return false;

      String cleaned = dataRaw.trim();
      if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }

      String formatted = '';
      try {
        final parsed = DateTime.parse(cleaned);
        formatted = DateFormat('dd-MM').format(parsed);
      } catch (_) {
        final parts = cleaned.split(RegExp(r'[/\-]'));
        if (parts.length >= 2) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          formatted = '$day-$month';
        }
      }
      return formatted == today;
    }).toList();
  }

  double _calcularTotal(List<Pedido> pedidos) {
    return pedidos.fold(0.0, (sum, p) {
      return sum + (p.subTotal ?? 0.0);
    });
  }

  Map<String, int> _contarPorSlot(List<Pedido> pedidos) {
    final slots = {
      "09:00 - 12:00": 0,
      "12:00 - 15:00": 0,
      "15:00 - 18:00": 0,
      "18:00 - 21:00": 0,
    };
    for (var p in pedidos) {
      final horario = p.horarioAgendamento ?? '';
      if (slots.containsKey(horario)) {
        slots[horario] = slots[horario]! + 1;
      }
    }
    return slots;
  }

  Map<String, int> _contarStatus(List<Pedido> pedidos) {
    final count = {
      "Saiu pra Entrega": 0,
      "Registrado": 0,
      "Concluído": 0,
      "Cancelado": 0,
    };
    for (var p in pedidos) {
      final status = p.status ?? 'Registrado';
      if (count.containsKey(status)) {
        count[status] = count[status]! + 1;
      }
    }
    return count;
  }

  Widget _buildMetricsCard(double totalValue, int totalOrders) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Valor Total do Dia", style: TextStyle(fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 6),
                Text(
                  "R\$ ${totalValue.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            Chip(
              label: Text("$totalOrders Pedidos", style: const TextStyle(color: Colors.white, fontSize: 16)),
              backgroundColor: primaryColor,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedidosPorSlotCard(Map<String, int> slots) {
    final maxY = slots.values.isNotEmpty
        ? (slots.values.reduce((a, b) => a > b ? a : b) + 2.0).toDouble()
        : 10.0;

    final keys = slots.keys.toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pedidos por Slot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < keys.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(keys[index], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawHorizontalLine: true),
                  borderData: FlBorderData(show: false),
                  barGroups: slots.entries.toList().asMap().entries.map((e) {
                    final index = e.key;
                    final slot = e.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: slot.value.toDouble(),
                          color: primaryColor,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Map<String, int> statusCount, int totalOrders) {
    final Map<String, Color> statusColors = {
      "Saiu pra Entrega": primaryColor,
      "Registrado": Colors.blue[300]!,
      "Concluído": Colors.green,
      "Cancelado": Colors.grey[700]!,
    };

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status dos Pedidos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 1,
                  centerSpaceRadius: 50,
                  pieTouchData: PieTouchData(enabled: true),
                  sections: statusCount.entries.map((e) {
                    final status = e.key;
                    final count = e.value;
                    return PieChartSectionData(
                      value: count.toDouble(),
                      title: "$count",
                      radius: 65,
                      titlePositionPercentageOffset: 0.55,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      color: statusColors[status] ?? Colors.grey,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statusCount.entries.map((e) {
                final status = e.key;
                final count = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(color: statusColors[status], borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text("$status ($count)", style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}