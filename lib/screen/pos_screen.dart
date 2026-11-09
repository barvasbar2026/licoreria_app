import 'package:flutter/material.dart';
import 'package:licoreria_app/models/auditoria_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto_model.dart';
import '../models/venta_model.dart';
import '../models/usuario_model.dart';

class PosScreen extends StatefulWidget {
  final Usuario usuarioSesion;

  const PosScreen({super.key, required this.usuarioSesion});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _supabase = Supabase.instance.client;
  List<Producto> _productos = [];
  final List<CarritoItem> _carrito = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase.from('productos').select().order('nombre');
      final lista = (res as List).map((e) => Producto.fromMap(e)).toList();
      setState(() {
        _productos = lista;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _agregarAlCarrito(Producto prod) {
    setState(() {
      final index = _carrito.indexWhere((item) => item.productoId == prod.id);
      if (index != -1) {
        _carrito[index].cantidad++;
      } else {
        _carrito.add(
          CarritoItem(
            productoId: prod.id!,
            nombreProducto: prod.nombre,
            precio: prod.precioVenta,
          ),
        );
      }
    });
  }

  double get _totalVenta =>
      _carrito.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _procesarVenta() async {
    if (_carrito.isEmpty) return;

    try {
      final ventaRes =
          await _supabase
              .from('ventas')
              .insert({
                'total': _totalVenta,
                'usuario_id': widget.usuarioSesion.id,
                'nombre_usuario': widget.usuarioSesion.nombre,
              })
              .select()
              .single();

      final ventaId = ventaRes['id'];

      for (var item in _carrito) {
        await _supabase.from('detalle_ventas').insert({
          'venta_id': ventaId,
          'producto_id': item.productoId,
          'cantidad': item.cantidad,
          'precio_unitario': item.precio,
        });
      }

      await AuditoriaService.registrarMovimiento(
        usuario: widget.usuarioSesion,
        tipoAccion: 'VENTA',
        categoria: 'VENTAS',
        descripcion:
            'Realizó la venta #$ventaId por un total de \$${_totalVenta.toStringAsFixed(2)}',
      );

      setState(() => _carrito.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Venta registrada exitosamente y stock descontado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al procesar venta: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas (POS)'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _productos.length,
                      itemBuilder: (context, index) {
                        final prod = _productos[index];
                        return InkWell(
                          onTap: () => _agregarAlCarrito(prod),
                          child: Card(
                            color: Colors.deepOrange.shade50,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    prod.nombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '\$${prod.precioVenta.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ítems en pedido: ${_carrito.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total: \$${_totalVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _carrito.isEmpty ? null : _procesarVenta,
                            child: const Text(
                              'COBRAR Y REGISTRAR VENTA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
