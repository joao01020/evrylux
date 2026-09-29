import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_web.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> bootstrapEvrylux(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.trim().isEmpty || _supabasePublishableKey.trim().isEmpty) {
    runApp(const _WebConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: _supabaseUrl.trim(),
    publishableKey: _supabasePublishableKey.trim(),
  );

  runApp(const EvryluxWebApp());
}

class _WebConfigurationErrorApp extends StatelessWidget {
  const _WebConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_rounded, size: 48),
                  SizedBox(height: 18),
                  Text(
                    'EVRYLUX Web não foi configurado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Execute pelos scripts scripts/run_web.sh ou '
                    'scripts/build_web.sh. Eles carregam SUPABASE_URL e '
                    'SUPABASE_PUBLISHABLE_KEY do .env e enviam os valores '
                    'como dart-define.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
