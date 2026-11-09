import 'package:flutter/material.dart';
import 'package:licoreria_app/models/auditoria_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto_model.dart';
import '../models/insumo_model.dart';
import '../models/usuario_model.dart';

class ProductosScreen extends StatefulWidget {
  final Usuario usuarioSesion;

  const ProductosScreen({super.key, required this.usuarioSesion});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _supabase = Supabase.instance.client;
  List<Producto> _productos = [];
  List<Insumo> _insumosDisponibles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final resInsumos = await _supabase.from('insumos').select().order('nombre');
      _insumosDisponibles = (resInsumos as List).map((e) => Insumo.fromMap(e)).toList();

      final resProductos = await _supabase
          .from('productos')
          .select('*, recetas(*, insumos(nombre))')
          .order('nombre');

      final listaProds = (resProductos as List).map((prodMap) {
        final recetasList = (prodMap['recetas'] as List? ?? [])
            .map((r) => RecetaItem.fromMap(r))
            .toList();
        return Producto.fromMap(prodMap, receta: recetasList);
      }).toList();

      setState(() {
        _productos = listaProds;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tragos: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _mostrarFormularioCrearTrago() {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    List<dynamic> recetaTemporal = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20, left: 20, right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nuevo Trago / Producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del Trago (Ej: Tinto de Verano)'),
                    ),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio de Venta (\$ Target)'),
                    ),
                    const SizedBox(height: 15),
                    const Text('Receta e Ingredientes:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),

                    ...recetaTemporal.map((item) {
                      return ListTile(
                        dense: true,
                        title: Text(item['insumo_nombre']),
                        subtitle: Text('Cantidad Requerida: ${item['cantidad']} ${item['unidad']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setModalState(() {
                              recetaTemporal.remove(item);
                            });
                          },
                        ),
                      );
                    }),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Insumo a Receta'),
                      onPressed: () => _dialogoAgregarInsumoReceta(setModalState, recetaTemporal),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                        onPressed: () async {
                          if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) return;

                          final resProd = await _supabase.from('productos').insert({
                            'nombre': nombreCtrl.text,
                            'precio_venta': double.parse(precioCtrl.text),
                          }).select().single();

                          final prodId = resProd['id'];

                          for (var item in recetaTemporal) {
                            await _supabase.from('recetas').insert({
                              'producto_id': prodId,
                              'insumo_id': item['insumo_id'],
                              'cantidad_requerida': item['cantidad'],
                            });
                          }

                          await AuditoriaService.registrarMovimiento(
                            usuario: widget.usuarioSesion,
                            tipoAccion: 'CREAR_TRAGO',
                            categoria: 'CONFIGURACION',
                            descripcion: 'Registró el trago "${nombreCtrl.text}" con precio \$${precioCtrl.text}',
                          );

                          if (mounted) Navigator.pop(context);
                          _cargarDatos();
                        },
                        child: const Text('Guardar Trago Completo'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _dialogoAgregarInsumoReceta(StateSetter setModalState, List recetaTemporal) {
    if (_insumosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes registrar insumos en el inventario.')),
      );
      return;
    }

    Insumo insumoSeleccionado = _insumosDisponibles.first;
    final cantCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccionar Insumo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Insumo>(
                    value: insumoSeleccionado,
                    items: _insumosDisponibles.map((i) {
                      return DropdownMenuItem(value: i, child: Text(i.nombre));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          insumoSeleccionado = val;
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: cantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad (${insumoSeleccionado.unidadMedida})',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (cantCtrl.text.isEmpty) return;
                    setModalState(() {
                      recetaTemporal.add({
                        'insumo_id': insumoSeleccionado.id,
                        'insumo_nombre': insumoSeleccionado.nombre,
                        'cantidad': double.parse(cantCtrl.text),
                        'unidad': insumoSeleccionado.unidadMedida,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carta de Tragos & Recetas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final prod = _productos[index];
                return ExpansionTile(
                  leading: const Icon(Icons.local_bar, color: Colors.deepOrange),
                  title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Precio: \$${prod.precioVenta}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _supabase.from('productos').delete().eq('id', prod.id!);
                      await AuditoriaService.registrarMovimiento(
                        usuario: widget.usuarioSesion,
                        tipoAccion: 'ELIMINAR_TRAGO',
                        categoria: 'CONFIGURACION',
                        descripcion: 'Eliminó el trago "${prod.nombre}"',
                      );
                      _cargarDatos();
                    },
                  ),
                  children: prod.receta.map((r) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 40, right: 20),
                      title: Text(r.nombreInsumo),
                      subtitle: Text('Consumo por trago: ${r.cantidadRequerida} ml/unid'),
                    );
                  }).toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioCrearTrago,
        child: const Icon(Icons.add),
      ),
    );
  }
}