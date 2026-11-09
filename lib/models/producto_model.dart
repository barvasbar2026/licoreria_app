class RecetaItem {
  final int? id;
  final int insumoId;
  final String nombreInsumo;
  final double cantidadRequerida;

  RecetaItem({
    this.id,
    required this.insumoId,
    required this.nombreInsumo,
    required this.cantidadRequerida,
  });

  factory RecetaItem.fromMap(Map<String, dynamic> map) {
    return RecetaItem(
      id: map['id'],
      insumoId: map['insumo_id'],
      nombreInsumo: map['insumos'] != null ? map['insumos']['nombre'] : '',
      cantidadRequerida: (map['cantidad_requerida'] as num).toDouble(),
    );
  }
}

class Producto {
  final int? id;
  final String nombre;
  final double precioVenta;
  final String? imagenUrl;
  final List<RecetaItem> receta;

  Producto({
    this.id,
    required this.nombre,
    required this.precioVenta,
    this.imagenUrl,
    this.receta = const [],
  });

  factory Producto.fromMap(
    Map<String, dynamic> map, {
    List<RecetaItem> receta = const [],
  }) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precioVenta: (map['precio_venta'] as num).toDouble(),
      imagenUrl: map['imagen_url'],
      receta: receta,
    );
  }
}
