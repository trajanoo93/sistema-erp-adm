// lib/models/pedido_model.dart
class Pedido {
  final String id;
  final String data;
  final String horario;
  final String bairro;
  final String nome;
  final String pagamento;
  final double subTotal;
  final double total;
  final String vendedor;
  final double taxaEntrega;
  final String status;
  final String entregador;
  final String rua;
  final String numero;
  final String cep;
  final String complemento;
  final String latitude;
  final String longitude;
  final String unidade;
  final String cidade;
  final String tipoEntrega;
  final String dataAgendamento;
  final String horarioAgendamento;
  final String telefone;
  final String observacao;
  final String produtos;
  final String rastreio;
  final String? nomeCupom;
  final double? porcentagemCupom;
  final double? descontoGiftCard; // NOME CORRETO

  Pedido({
    required this.id,
    required this.data,
    required this.horario,
    required this.bairro,
    required this.nome,
    required this.pagamento,
    required this.subTotal,
    required this.total,
    required this.vendedor,
    required this.taxaEntrega,
    required this.status,
    required this.entregador,
    required this.rua,
    required this.numero,
    required this.cep,
    required this.complemento,
    required this.latitude,
    required this.longitude,
    required this.unidade,
    required this.cidade,
    required this.tipoEntrega,
    required this.dataAgendamento,
    required this.horarioAgendamento,
    required this.telefone,
    required this.observacao,
    required this.produtos,
    required this.rastreio,
    this.nomeCupom,
    this.porcentagemCupom,
    this.descontoGiftCard,
  });

  // FUNÇÃO AUXILIAR (adicionada)
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'].toString(),
      data: json['data']?.toString() ?? '',
      horario: json['horario']?.toString() ?? '',
      bairro: json['bairro']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      pagamento: json['pagamento']?.toString() ?? '',
      subTotal: _toDouble(json['subTotal']),
      total: _toDouble(json['total']),
      vendedor: json['vendedor']?.toString() ?? '',
      taxaEntrega: _toDouble(json['taxa_entrega']),
      status: json['status']?.toString() ?? '',
      entregador: json['entregador']?.toString() ?? '',
      rua: json['rua']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      cep: json['cep']?.toString() ?? '',
      complemento: json['complemento']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      unidade: json['unidade']?.toString() ?? '',
      cidade: json['cidade']?.toString() ?? '',
      tipoEntrega: json['tipo_entrega']?.toString() ?? '',
      dataAgendamento: json['data_agendamento']?.toString() ?? '',
      horarioAgendamento: json['horario_agendamento']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      observacao: json['observacao']?.toString() ?? '',
      produtos: json['produtos']?.toString() ?? '',
      rastreio: json['rastreio']?.toString() ?? '',
      nomeCupom: json['AG']?.toString(),
      porcentagemCupom: _toDouble(json['AH']),
      descontoGiftCard: _toDouble(json['AI']), // CORRIGIDO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'horario': horario,
      'bairro': bairro,
      'nome': nome,
      'pagamento': pagamento,
      'subTotal': subTotal,
      'total': total,
      'vendedor': vendedor,
      'taxa_entrega': taxaEntrega,
      'status': status,
      'entregador': entregador,
      'rua': rua,
      'numero': numero,
      'cep': cep,
      'complemento': complemento,
      'latitude': latitude,
      'longitude': longitude,
      'unidade': unidade,
      'cidade': cidade,
      'tipo_entrega': tipoEntrega,
      'data_agendamento': dataAgendamento,
      'horario_agendamento': horarioAgendamento,
      'telefone': telefone,
      'observacao': observacao,
      'produtos': produtos,
      'rastreio': rastreio,
      'AG': nomeCupom,
      'AH': porcentagemCupom,
      'AI': descontoGiftCard,
    };
  }

  Pedido copyWith({String? status}) {
    return Pedido(
      id: id,
      data: data,
      horario: horario,
      bairro: bairro,
      nome: nome,
      pagamento: pagamento,
      subTotal: subTotal,
      total: total,
      vendedor: vendedor,
      taxaEntrega: taxaEntrega,
      status: status ?? this.status,
      entregador: entregador,
      rua: rua,
      numero: numero,
      cep: cep,
      complemento: complemento,
      latitude: latitude,
      longitude: longitude,
      unidade: unidade,
      cidade: cidade,
      tipoEntrega: tipoEntrega,
      dataAgendamento: dataAgendamento,
      horarioAgendamento: horarioAgendamento,
      telefone: telefone,
      observacao: observacao,
      produtos: produtos,
      rastreio: rastreio,
      nomeCupom: nomeCupom,
      porcentagemCupom: porcentagemCupom,
      descontoGiftCard: descontoGiftCard,
    );
  }
}