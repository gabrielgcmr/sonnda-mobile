import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final String currentRoute;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _signOut(BuildContext context) async {
    Navigator.of(context).pop();
    await _client.auth.signOut();

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _openRoute(BuildContext context, String route) {
    Navigator.of(context).pop();

    if (currentRoute == route) {
      return;
    }

    if (route == AppRoutes.patients) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => route.isFirst,
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).pop();

    if (currentRoute == AppRoutes.profile) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.profile,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    final email = user?.email?.trim() ?? '';
    final drawerEmail = email.isEmpty ? 'Usuario' : email;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Sonnda'),
              accountEmail: Text(drawerEmail),
              currentAccountPicture: CircleAvatar(
                child: Text(drawerEmail.characters.first.toUpperCase()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Buscar paciente'),
              selected: currentRoute == AppRoutes.patients,
              onTap: () => _openRoute(context, AppRoutes.patients),
            ),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Pressao arterial'),
              selected: currentRoute == AppRoutes.pressao,
              onTap: () => _openRoute(context, AppRoutes.pressao),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              selected: currentRoute == AppRoutes.profile,
              onTap: () => _openProfile(context),
            ),
            SwitchListTile(
              secondary: Icon(
                isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Tema escuro'),
              value: isDarkMode,
              onChanged: onDarkModeChanged,
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
