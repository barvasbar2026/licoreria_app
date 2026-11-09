import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _supabase = Supabase.instance.client;
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _iniciarSesion() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('usuario', _userCtrl.text.trim())
          .eq('password', _passCtrl.text.trim())
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario o contraseña incorrectos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final usuarioLogueado = Usuario.fromMap(response);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(usuarioSesion: usuarioLogueado),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_bar, size: 60, color: Colors.deepOrange),
                    const SizedBox(height: 10),
                    const Text(
                      'Licorería App',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _iniciarSesion,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('INGRESAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}