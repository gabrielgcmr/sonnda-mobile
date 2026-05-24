import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'navigation/app_routes.dart';
import 'pages/auth_page.dart';
import 'pages/patient_create_page.dart';
import 'pages/patient_search_page.dart';
import 'pages/pressao_page.dart';
import 'pages/profile_page.dart';

class SonndaApp extends StatefulWidget {
  const SonndaApp({super.key});

  @override
  State<SonndaApp> createState() => _SonndaAppState();
}

class _SonndaAppState extends State<SonndaApp> {
  static const String _darkModeKey = 'dark_mode_enabled';

  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_darkModeKey);

    if (!mounted || enabled == null) {
      return;
    }

    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setDarkMode(bool enabled) {
    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_darkModeKey, enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonnda - Pressao Arterial',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      onGenerateRoute: _buildRoute,
      home: AuthGate(
        isDarkMode: _themeMode == ThemeMode.dark,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }

  Route<void> _buildRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        return switch (settings.name) {
          AppRoutes.patientCreate => PatientCreatePage(
            isDarkMode: _themeMode == ThemeMode.dark,
            onDarkModeChanged: _setDarkMode,
          ),
          AppRoutes.pressao => PressaoPage(
            isDarkMode: _themeMode == ThemeMode.dark,
            onDarkModeChanged: _setDarkMode,
          ),
          AppRoutes.profile => ProfilePage(
            isDarkMode: _themeMode == ThemeMode.dark,
            onDarkModeChanged: _setDarkMode,
          ),
          _ => PatientSearchPage(
            isDarkMode: _themeMode == ThemeMode.dark,
            onDarkModeChanged: _setDarkMode,
          ),
        };
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session != null) {
          return PatientSearchPage(
            isDarkMode: isDarkMode,
            onDarkModeChanged: onDarkModeChanged,
          );
        }

        return const AuthPage();
      },
    );
  }
}
