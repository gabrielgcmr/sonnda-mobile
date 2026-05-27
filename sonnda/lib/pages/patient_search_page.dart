import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/app_routes.dart';
import 'patient_create_page.dart';
import '../widgets/app_drawer.dart';

class PatientSearchPage extends StatefulWidget {
  const PatientSearchPage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends State<PatientSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _patientsFuture = _loadPatients();

  String _query = '';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadPatients() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      return [];
    }

    final userProfile = await _client
        .from('users')
        .select('id')
        .eq('auth_subject', authUser.id)
        .maybeSingle();

    final userId = userProfile?['id']?.toString();

    if (userId == null || userId.isEmpty) {
      return [];
    }

    final ownedPatients = await _client
        .from('patients')
        .select(
          'id, full_name, cpf, cns, birth_date, gender, phone, owner_user_id',
        )
        .eq('owner_user_id', userId)
        .isFilter('deleted_at', null)
        .order('full_name');

    final accessRows = await _client
        .from('patient_access')
        .select('patient_id')
        .eq('grantee_id', userId)
        .isFilter('revoked_at', null);

    final patientIds = <String>{
      for (final row in accessRows)
        if (row['patient_id'] != null) row['patient_id'].toString(),
    };

    final patientsById = <String, Map<String, dynamic>>{
      for (final patient in ownedPatients)
        if (patient['id'] != null)
          patient['id'].toString(): Map<String, dynamic>.from(patient),
    };

    for (final patientId in patientIds) {
      if (patientsById.containsKey(patientId)) {
        continue;
      }

      final patient = await _client
          .from('patients')
          .select(
            'id, full_name, cpf, cns, birth_date, gender, phone, owner_user_id',
          )
          .eq('id', patientId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (patient != null) {
        patientsById[patientId] = Map<String, dynamic>.from(patient);
      }
    }

    final patients = patientsById.values.toList()
      ..sort((a, b) {
        final left = _patientText(a['full_name']).toLowerCase();
        final right = _patientText(b['full_name']).toLowerCase();
        return left.compareTo(right);
      });

    return patients;
  }

  void _refreshPatients() {
    setState(() {
      _patientsFuture = _loadPatients();
    });
  }

  void _updateQuery(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
    });
  }

  List<Map<String, dynamic>> _filterPatients(List<Map<String, dynamic>> items) {
    if (_query.isEmpty) {
      return items;
    }

    return items.where((patient) {
      final searchable = [
        patient['full_name'],
        patient['cpf'],
        patient['cns'],
        patient['phone'],
      ].map(_patientText).join(' ').toLowerCase();

      return searchable.contains(_query);
    }).toList();
  }

  Future<void> _openCreatePatient() async {
    try {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PatientCreatePage(
            isDarkMode: widget.isDarkMode,
            onDarkModeChanged: widget.onDarkModeChanged,
          ),
        ),
      );

      if (created == true && mounted) {
        _refreshPatients();
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Erro ao abrir cadastro de paciente: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel abrir o cadastro: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          IconButton(
            onPressed: _refreshPatients,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePatient,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Adicionar'),
      ),
      drawer: AppDrawer(
        currentRoute: AppRoutes.patients,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar por nome, CPF, CNS ou telefone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _updateQuery('');
                        },
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: _updateQuery,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _patientsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.error_outline,
                      title: 'Nao foi possivel carregar os pacientes.',
                      subtitle: 'Verifique as permissoes da tabela patients.',
                      action: FilledButton.icon(
                        onPressed: _refreshPatients,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    );
                  }

                  final patients = _filterPatients(snapshot.data ?? []);

                  if (patients.isEmpty) {
                    return _EmptyState(
                      icon: Icons.person_search_outlined,
                      title: _query.isEmpty
                          ? 'Nenhum paciente disponivel.'
                          : 'Nenhum paciente encontrado.',
                      subtitle: _query.isEmpty
                          ? 'Pacientes proprios ou compartilhados aparecerao aqui.'
                          : 'Tente buscar por outro dado do paciente.',
                      action: _query.isEmpty
                          ? FilledButton.icon(
                              onPressed: _openCreatePatient,
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Adicionar paciente'),
                            )
                          : null,
                    );
                  }

                  return ListView.separated(
                    itemCount: patients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _PatientTile(patient: patients[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _patientText(Object? value) {
  return value?.toString().trim() ?? '';
}

String _emptyPatientText(Object? value, {String fallback = 'Nao informado'}) {
  final text = _patientText(value);
  return text.isEmpty ? fallback : text;
}

String _maskedCpf(Object? value) {
  final digits = _patientText(value).replaceAll(RegExp(r'\D'), '');

  if (digits.length != 11) {
    return _emptyPatientText(value);
  }

  return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final fullName = _emptyPatientText(patient['full_name']);
    final birthDate = _emptyPatientText(patient['birth_date']);
    final cpf = _maskedCpf(patient['cpf']);
    final phone = _emptyPatientText(patient['phone']);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(fullName.characters.first.toUpperCase()),
        ),
        title: Text(fullName),
        subtitle: Text('Nascimento: $birthDate\nCPF: $cpf\nTelefone: $phone'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paciente selecionado: $fullName')),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
