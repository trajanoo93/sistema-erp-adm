// lib/widgets/scheduling_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../globals.dart';

class SchedulingSection extends StatefulWidget {
  final String shippingMethod;
  final String storeFinal;
  final Function(String, String) onDateTimeUpdated;
  final Function() onSchedulingChanged;
  final DateTime? initialDate;
  final String? initialTimeSlot;

  const SchedulingSection({
    Key? key,
    required this.shippingMethod,
    required this.storeFinal,
    required this.onDateTimeUpdated,
    required this.onSchedulingChanged,
    this.initialDate,
    this.initialTimeSlot,
  }) : super(key: key);

  @override
  State<SchedulingSection> createState() => _SchedulingSectionState();
}

class _SchedulingSectionState extends State<SchedulingSection> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<String> _availableTimeSlots = [];
  final primaryColor = const Color(0xFFF28C38);

  Future<void> _log(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final unidade = (currentUser?.unidade ?? 'Desconhecida').replaceAll(' ', '_').toLowerCase();
      final appDir = Directory('${dir.path}/ERPUnificado/$unidade');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final file = File('${appDir.path}/app_logs.txt');
      await file.writeAsString('[${DateTime.now()}] [Agendamento] $message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Falha ao logar agendamento: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _updateTimeSlots();
    _selectedTimeSlot = widget.initialTimeSlot != null && _availableTimeSlots.contains(widget.initialTimeSlot)
        ? widget.initialTimeSlot
        : _availableTimeSlots.isNotEmpty
            ? _availableTimeSlots.first
            : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateParent();
    });
  }

  @override
  void didUpdateWidget(SchedulingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shippingMethod != oldWidget.shippingMethod ||
        widget.initialDate != oldWidget.initialDate ||
        widget.initialTimeSlot != oldWidget.initialTimeSlot) {
      setState(() {
        _selectedDate = widget.initialDate ?? DateTime.now();
        _updateTimeSlots();
        _selectedTimeSlot = widget.initialTimeSlot != null && _availableTimeSlots.contains(widget.initialTimeSlot)
            ? widget.initialTimeSlot
            : _availableTimeSlots.isNotEmpty
                ? _availableTimeSlots.first
                : null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateParent();
      });
    }
  }

  void _updateTimeSlots() {
    final now = DateTime.now();
    final isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
    final isSunday = _selectedDate?.weekday == DateTime.sunday;
    final currentHour = now.hour + (now.minute / 60.0);

    setState(() {
      // Define slots base conforme dia e método
      if (isSunday) {
        _availableTimeSlots = widget.shippingMethod == 'pickup'
            ? ['09:00 - 12:00']
            : ['09:00 - 12:00', '12:00 - 15:00'];
      } else {
        _availableTimeSlots = widget.shippingMethod == 'pickup'
            ? ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00']
            : ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00', '18:00 - 21:00'];
      }

      // Se for hoje, filtra horários passados
      if (isToday) {
        _availableTimeSlots = _availableTimeSlots.where((slot) {
          final parts = slot.split('-').map((s) => s.trim()).toList();
          
          // Pega a hora de INÍCIO do slot (não o fim)
          final startHour = double.parse(parts[0].split(':')[0]) + 
                           (double.parse(parts[0].split(':')[1]) / 60.0);
          
          // Mostra apenas slots que ainda não começaram ou estão acontecendo agora
          // Adiciona margem de 30 minutos para dar tempo do pedido
          return (startHour - currentHour) >= -0.5;
        }).toList();

        // Se não sobrou nenhum horário, não força nada (lista vazia)
        // O usuário terá que escolher outro dia
        if (_availableTimeSlots.isEmpty) {
          _log('AVISO: Todos os horários de hoje já passaram. Hora atual: ${now.hour}:${now.minute}');
        }
      }

      // Atualiza o slot selecionado
      if (_selectedTimeSlot == null || !_availableTimeSlots.contains(_selectedTimeSlot)) {
        _selectedTimeSlot = _availableTimeSlots.isNotEmpty ? _availableTimeSlots.first : null;
      }
    });

    _log('Horários disponíveis: $_availableTimeSlots (hoje: $isToday, domingo: $isSunday, hora atual: ${now.hour}:${now.minute})');
  }

  // MÉTODO CORRIGIDO: Usa showDatePicker nativo ao invés de Navigator.push
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        _updateTimeSlots();
      });
      _updateParent();
      _log('Data selecionada: ${DateFormat('dd/MM/yyyy').format(picked)}');
    }
  }

  void _updateParent() {
    if (mounted && _selectedDate != null && _selectedTimeSlot != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      widget.onDateTimeUpdated(formatted, _selectedTimeSlot!);
      widget.onSchedulingChanged();
      _log('Agendamento atualizado: $formatted - $_selectedTimeSlot');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidade = currentUser?.unidade ?? 'CD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Agendamento',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: widget.shippingMethod == 'delivery' ? 'Data de Entrega' : 'Data de Retirada',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                ),
                controller: TextEditingController(
                  text: _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Selecione',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Selecione a data' : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: _selectedTimeSlot,
            decoration: InputDecoration(
              labelText: widget.shippingMethod == 'delivery' ? 'Horário de Entrega' : 'Horário de Retirada',
              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
              prefixIcon: Icon(Icons.access_time, color: primaryColor),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            items: _availableTimeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot))).toList(),
            onChanged: (value) {
              if (value != null && mounted) {
                setState(() => _selectedTimeSlot = value);
                _updateParent();
                _log('Horário alterado: $value');
              }
            },
            validator: (v) => v == null ? 'Selecione um horário' : null,
          ),
        ),
        // Mensagem quando não há horários disponíveis
        if (_availableTimeSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Não há mais horários disponíveis para hoje. Selecione outra data.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}