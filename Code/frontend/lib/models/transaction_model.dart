class TransactionModel {
  final int? id;
  final int? usuarioId;
  final String descricao;
  final double valor;
  final String tipo; // 'receita' ou 'despesa'
  final String categoria;
  final DateTime? dataTransacao;

  TransactionModel({
    this.id,
    this.usuarioId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria,
    this.dataTransacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'categoria': categoria,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      usuarioId: map['usuario_id'],
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'] ?? '',
      categoria: map['categoria'] ?? '',
      dataTransacao: map['data_transacao'] != null
          ? DateTime.parse(map['data_transacao'])
          : null,
    );
  }
}
