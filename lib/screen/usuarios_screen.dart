import 'package:flutter/material.dart';
import 'package:licoreria_app/models/auditoria_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class UsuariosScreen extends StatefulWidget {
  final Usuario usuarioSesion;

  const UsuariosScreen({super.key, required this.usuarioSesion});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _supabase = Supabase.instance.client;
  List<Usuario> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase.from('usuarios').select().order('nombre');
      final lista = (res as List).map((e) => Usuario.fromMap(e)).toList();
      setState(() {
        _usuarios = lista;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _dialogoCrearUsuario() {
    final nombreCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    String rol = 'trabajador';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Registrar Nuevo Usuario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                      ),
                    ),
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Usuario',
                      ),
                    ),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                    ),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN de Autorización',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: rol,
                      items: const [
                        DropdownMenuItem(
                          value: 'trabajador',
                          child: Text('Trabajador / Barman'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (val) => setModalState(() => rol = val!),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (nombreCtrl.text.isEmpty ||
                            userCtrl.text.isEmpty ||
                            passCtrl.text.isEmpty)
                          return;

                        await _supabase.from('usuarios').insert({
                          'nombre': nombreCtrl.text,
                          'usuario': userCtrl.text.trim(),
                          'password': passCtrl.text.trim(),
                          'pin_autorizacion': pinCtrl.text.trim(),
                          'rol': rol,
                        });

                        await AuditoriaService.registrarMovimiento(
                          usuario: widget.usuarioSesion,
                          tipoAccion: 'CREAR_USUARIO',
                          categoria: 'USUARIOS',
                          descripcion:
                              'Creó el usuario "${userCtrl.text}" con rol $rol',
                        );

                        if (mounted) Navigator.pop(context);
                        _cargarUsuarios();
                      },
                      child: const Text('Crear Usuario'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final u = _usuarios[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          u.rol == 'admin' ? Colors.deepOrange : Colors.blue,
                      child: Icon(
                        u.rol == 'admin' ? Icons.security : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(u.nombre),
                    subtitle: Text('Usuario: ${u.usuario} | Rol: ${u.rol}'),
                    trailing:
                        u.usuario == 'admin'
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _supabase
                                    .from('usuarios')
                                    .delete()
                                    .eq('id', u.id);
                                await AuditoriaService.registrarMovimiento(
                                  usuario: widget.usuarioSesion,
                                  tipoAccion: 'ELIMINAR_USUARIO',
                                  categoria: 'USUARIOS',
                                  descripcion:
                                      'Eliminó al usuario "${u.nombre}" (@${u.usuario})',
                                );
                                _cargarUsuarios();
                              },
                            ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _dialogoCrearUsuario,
        child: const Icon(Icons.add),
      ),
    );
  }
}
