class MedicaoPressao {
  const MedicaoPressao({required this.sistolica, required this.diastolica});

  final double sistolica;
  final double diastolica;

  double get media => (sistolica + diastolica) / 2;

  Map<String, dynamic> toJson() {
    return {'sistolica': sistolica, 'diastolica': diastolica};
  }

  factory MedicaoPressao.fromJson(Map<String, dynamic> json) {
    final sistolica = (json['sistolica'] as num?)?.toDouble() ?? 0;
    final diastolica = (json['diastolica'] as num?)?.toDouble() ?? 0;
    return MedicaoPressao(sistolica: sistolica, diastolica: diastolica);
  }
}
