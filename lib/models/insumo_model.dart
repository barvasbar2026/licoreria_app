class Insumo {
  final int? id;
  final String nombre;
  final String unidadMedida; // 'ml', 'unidades', 'gr'
  final double stockActual;
  final double costoUnidad;
  final String? imagenUrl;

  Insumo({
    this.id,
    required this.nombre,
    required this.unidadMedida,
    required this.stockActual,
    required this.costoUnidad,
    this.imagenUrl,
  });

  // Convertir de Map (Supabase) a Objeto Dart
  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id'],
      nombre: map['nombre'],
      unidadMedida: map['unidad_medida'],
      stockActual: (map['stock_actual'] as num).toDouble(),
      costoUnidad: (map['costo_unidad'] as num).toDouble(),
      imagenUrl: map['imagen_url'],
    );
  }

  // Convertir de Objeto Dart a Map para guardar en Supabase
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'unidad_medida': unidadMedida,
      'stock_actual': stockActual,
      'costo_unidad': costoUnidad,
      'imagen_url': imagenUrl,
    };
  }
}