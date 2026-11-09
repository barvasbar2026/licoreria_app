class Usuario {
  final int id;
  final String nombre;
  final String usuario;
  final String rol; // 'admin' o 'trabajador'
  final String pinAutorizacion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
    required this.pinAutorizacion,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nombre: map['nombre'],
      usuario: map['usuario'] ?? '',
      rol: map['rol'] ?? 'trabajador',
      pinAutorizacion: map['pin_autorizacion'] ?? '1234',
    );
  }
}
