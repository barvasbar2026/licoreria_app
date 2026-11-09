import 'package:flutter/material.dart';
import 'package:licoreria_app/screen/dashboard_screen.dart';
import 'package:licoreria_app/screen/insumos_screen.dart';
import 'package:licoreria_app/screen/login_screen.dart';
import 'package:licoreria_app/screen/pos_screen.dart';
import 'package:licoreria_app/screen/productos_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase con tus credenciales
  await Supabase.initialize(
    url: 'https://hsupbrqhsvnthycchfhk.supabase.co',
    publishableKey: 'sb_publishable_9rAoUT5EWpoPDvtcertqjQ_CkFZY3vu',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Licorería App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepOrange, useMaterial3: true),
      home: LoginScreen(),
    );
  }
}
