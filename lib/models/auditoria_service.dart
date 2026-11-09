import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class AuditoriaService {
  static final _supabase = Supabase.instance.client;

  static Future<void> registrarMovimiento({
    required Usuario usuario,
    required String tipoAccion,
    required String categoria,
    required String descripcion,
  }) async {
    try {
      await _supabase.from('movimientos').insert({
        'usuario_id': usuario.id,
        'nombre_usuario': usuario.nombre,
        'tipo_accion': tipoAccion,
        'categoria': categoria,
        'descripcion': descripcion,
      });
    } catch (e) {
      // Ignorar error para no bloquear la app si falla el log
      print('Error al guardar movimiento de auditoría: $e');
    }
  }
}