class CarritoItem {
  final int productoId;
  final String nombreProducto;
  final double precio;
  int cantidad;

  CarritoItem({
    required this.productoId,
    required this.nombreProducto,
    required this.precio,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}