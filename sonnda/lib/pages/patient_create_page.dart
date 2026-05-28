import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/app_routes.dart';
import '../widgets/app_drawer.dart';

class PatientCreatePage extends StatefulWidget {
  const PatientCreatePage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<PatientCreatePage> createState() => _PatientCreatePageState();
}

class _PatientCreatePageState extends State<PatientCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _raceController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  String _relationType = 'guardian';
  bool _isSaving = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _fullNameController.dispose();
    _cpfController.dispose();
    _cnsController.dispose();
    _phoneController.dispose();
    _raceController.dispose();
    super.dispose();
  }

  Future<String?> _loadCurrentUserId() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      return null;
    }

    final profile = await _client
        .from('users')
        .select('id')
        .eq('auth_subject', authUser.id)
        .maybeSingle();

    return profile?['id']?.toString();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _birthDate = selected;
    });
  }

  Future<void> _savePatient() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = await _loadCurrentUserId();

      if (userId == null || userId.isEmpty) {
        throw const PatientCreateException(
          'Nao foi possivel identificar o usuario atual.',
        );
      }

      final patientPayload = <String, dynamic>{
        'full_name': _cleanText(_fullNameController.text),
        if (_relationType == 'self') 'owner_user_id': userId,
        if (_cleanText(_cpfController.text).isNotEmpty)
          'cpf': _onlyDigits(_cpfController.text),
        if (_cleanText(_cnsController.text).isNotEmpty)
          'cns': _onlyDigits(_cnsController.text),
        if (_birthDate != null) 'birth_date': _formatDate(_birthDate!),
        if (_gender != null) 'gender': _gender,
        if (_cleanText(_raceController.text).isNotEmpty)
          'race': _cleanText(_raceController.text),
        if (_cleanText(_phoneController.text).isNotEmpty)
          'phone': _cleanText(_phoneController.text),
      };

      final patient = await _client
          .from('patients')
          .insert(patientPayload)
          .select('id')
          .single();

      final patientId = patient['id']?.toString();

      if (patientId == null || patientId.isEmpty) {
        throw const PatientCreateException(
          'Paciente criado sem identificador retornado.',
        );
      }

      await _client.from('patient_access').insert({
        'patient_id': patientId,
        'grantee_id': userId,
        'relation_type': _relationType,
        'granted_by': userId,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paciente adicionado.')));
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nao foi possivel adicionar o paciente: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop(false);
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.patients);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Adicionar paciente'),
      ),
      drawer: AppDrawer(
        currentRoute: AppRoutes.patients,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_cleanText(value).isEmpty) {
                    return 'Informe o nome do paciente.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _relationType,
                decoration: const InputDecoration(
                  labelText: 'Seu vinculo com o paciente',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'guardian',
                    child: Text('Responsavel'),
                  ),
                  DropdownMenuItem(value: 'mother', child: Text('Mae')),
                  DropdownMenuItem(value: 'father', child: Text('Pai')),
                  DropdownMenuItem(value: 'self', child: Text('Sou eu')),
                  DropdownMenuItem(value: 'other', child: Text('Outro')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _relationType = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cnsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CNS',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: _isSaving ? null : _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Nao informado'
                        : _formatDate(_birthDate!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Genero',
                  prefixIcon: Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Feminino')),
                  DropdownMenuItem(value: 'male', child: Text('Masculino')),
                  DropdownMenuItem(value: 'other', child: Text('Outro')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _raceController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Raca/cor',
                  prefixIcon: Icon(Icons.palette_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _savePatient,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando' : 'Salvar paciente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientCreateException implements Exception {
  const PatientCreateException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _cleanText(Object? value) {
  return value?.toString().trim() ?? '';
}

String _onlyDigits(Object? value) {
  return _cleanText(value).replaceAll(RegExp(r'\D'), '');
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}
