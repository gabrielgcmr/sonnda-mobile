import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ewqwkbexpmxtrvmnifvz.supabase.co',
    anonKey: 'sb_publishable_sOZomuqeIvvS0LnJv2FQfw_upQtHjq9',
  );

  runApp(const SonndaApp());
}
