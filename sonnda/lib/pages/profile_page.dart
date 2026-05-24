import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/app_routes.dart';
import '../widgets/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>?> _profileFuture = _loadProfile();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final profile = await _client
        .from('users')
        .select()
        .eq('auth_subject', user.id)
        .maybeSingle();

    return profile;
  }

  String _value(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Nao informado' : text;
  }

  String _maskedCpf(Object? value) {
    final digits = value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

    if (digits.length != 11) {
      return _value(value);
    }

    return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
  }

  @override
  Widget build(BuildContext context) {
    final authUser = _client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      drawer: AppDrawer(
        currentRoute: AppRoutes.profile,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Nao foi possivel carregar o perfil.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          final profile = snapshot.data ?? <String, dynamic>{};
          final email = profile['email'] ?? authUser?.email;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  _initials(profile['full_name'] ?? email),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _value(profile['full_name']),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _value(email),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'CPF',
                value: _maskedCpf(profile['cpf']),
              ),
              _ProfileTile(
                icon: Icons.cake_outlined,
                label: 'Data de nascimento',
                value: _value(profile['birth_date']),
              ),
              _ProfileTile(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: _value(profile['phone']),
              ),
              _ProfileTile(
                icon: Icons.account_circle_outlined,
                label: 'Tipo de conta',
                value: _value(profile['account_type']),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(Object? value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return '?';
    }

    final parts = text.split(RegExp(r'\s+'));
    final first = parts.first.characters.first;

    if (parts.length == 1) {
      return first.toUpperCase();
    }

    return '$first${parts.last.characters.first}'.toUpperCase();
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
