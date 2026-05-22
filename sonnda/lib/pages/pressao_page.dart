import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medicao_pressao.dart';

class PressaoPage extends StatefulWidget {
  const PressaoPage({super.key});

  @override
  State<PressaoPage> createState() => _PressaoPageState();
}

class _PressaoPageState extends State<PressaoPage> {
  static const String _medicoesKey = 'mrpa_medicoes';

  final TextEditingController _sistolicaController = TextEditingController();
  final TextEditingController _diastolicaController = TextEditingController();

  final List<MedicaoPressao> _medicoes = [];
  double? _mediaPressao;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarMedicoes();
  }

  @override
  void dispose() {
    _sistolicaController.dispose();
    _diastolicaController.dispose();
    super.dispose();
  }

  void _calcularMedia() {
    final sistolica = double.tryParse(
      _sistolicaController.text.replaceAll(',', '.'),
    );
    final diastolica = double.tryParse(
      _diastolicaController.text.replaceAll(',', '.'),
    );

    setState(() {
      _erro = null;

      if (_sistolicaController.text.trim().isEmpty ||
          _diastolicaController.text.trim().isEmpty) {
        _mediaPressao = null;
        return;
      }

      if (sistolica == null || diastolica == null) {
        _mediaPressao = null;
        _erro = 'Digite apenas numeros validos.';
        return;
      }

      if (sistolica <= 0 || diastolica <= 0) {
        _mediaPressao = null;
        _erro = 'Os valores devem ser maiores que zero.';
        return;
      }

      _mediaPressao = (sistolica + diastolica) / 2;
    });
  }

  void _salvarMedicao() {
    final sistolica = double.tryParse(
      _sistolicaController.text.replaceAll(',', '.'),
    );
    final diastolica = double.tryParse(
      _diastolicaController.text.replaceAll(',', '.'),
    );

    setState(() {
      _erro = null;

      if (sistolica == null || diastolica == null) {
        _erro = 'Digite valores numericos validos para salvar.';
        return;
      }

      if (sistolica <= 0 || diastolica <= 0) {
        _erro = 'Os valores devem ser maiores que zero.';
        return;
      }

      _medicoes.add(
        MedicaoPressao(sistolica: sistolica, diastolica: diastolica),
      );
      _sistolicaController.clear();
      _diastolicaController.clear();
      _mediaPressao = null;
    });

    _persistirMedicoes();
  }

  void _removerMedicao(int index) {
    setState(() {
      _medicoes.removeAt(index);
    });

    _persistirMedicoes();
  }

  void _limparMedicoes() {
    setState(() {
      _medicoes.clear();
    });

    _persistirMedicoes();
  }

  Future<void> _carregarMedicoes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_medicoesKey);

    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return;
    }

    final medicoes = <MedicaoPressao>[];

    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        medicoes.add(MedicaoPressao.fromJson(item));
      } else if (item is Map) {
        medicoes.add(MedicaoPressao.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _medicoes
        ..clear()
        ..addAll(medicoes);
    });
  }

  Future<void> _persistirMedicoes() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _medicoes.map((item) => item.toJson()).toList();
    await prefs.setString(_medicoesKey, jsonEncode(payload));
  }

  double get _mediaSistolica {
    if (_medicoes.isEmpty) {
      return 0;
    }

    final soma = _medicoes.fold<double>(
      0,
      (total, item) => total + item.sistolica,
    );

    return soma / _medicoes.length;
  }

  double get _mediaDiastolica {
    if (_medicoes.isEmpty) {
      return 0;
    }

    final soma = _medicoes.fold<double>(
      0,
      (total, item) => total + item.diastolica,
    );

    return soma / _medicoes.length;
  }

  double get _mediaGeral {
    if (_medicoes.isEmpty) {
      return 0;
    }

    final somaDasMedias = _medicoes.fold<double>(
      0,
      (total, item) => total + item.media,
    );

    return somaDasMedias / _medicoes.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media da Pressao Arterial'),
        actions: [
          IconButton(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _sistolicaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Pressao sistolica (mmHg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calcularMedia(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _diastolicaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Pressao diastolica (mmHg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calcularMedia(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _calcularMedia,
              child: const Text('Calcular media'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _salvarMedicao,
              child: const Text('Salvar medicao MRPA'),
            ),
            const SizedBox(height: 20),
            if (_erro != null)
              Text(
                _erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_mediaPressao != null)
              Text(
                'Media da pressao: ${_mediaPressao!.toStringAsFixed(1)} mmHg',
                style: Theme.of(context).textTheme.titleLarge,
              )
            else
              const Text(
                'Informe os dois valores para calcular a media automaticamente.',
              ),
            const SizedBox(height: 20),
            Text(
              'Historico MRPA (${_medicoes.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_medicoes.isEmpty)
              const Text('Nenhuma medicao salva ainda.')
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media sistolica: ${_mediaSistolica.toStringAsFixed(1)} mmHg',
                      ),
                      Text(
                        'Media diastolica: ${_mediaDiastolica.toStringAsFixed(1)} mmHg',
                      ),
                      Text(
                        'Media geral das pressoes: ${_mediaGeral.toStringAsFixed(1)} mmHg',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _medicoes.length,
                  itemBuilder: (context, index) {
                    final medicao = _medicoes[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${medicao.sistolica.toStringAsFixed(0)} x ${medicao.diastolica.toStringAsFixed(0)} mmHg',
                        ),
                        subtitle: Text(
                          'Media: ${medicao.media.toStringAsFixed(1)} mmHg',
                        ),
                        trailing: IconButton(
                          onPressed: () => _removerMedicao(index),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remover',
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: _limparMedicoes,
                child: const Text('Limpar historico'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
