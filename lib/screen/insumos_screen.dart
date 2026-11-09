import 'package:flutter/material.dart';
import 'package:licoreria_app/models/auditoria_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insumo_model.dart';
import '../models/usuario_model.dart';

class InsumosScreen extends StatefulWidget {
  final Usuario usuarioSesion;

  const InsumosScreen({super.key, required this.usuarioSesion});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  final _supabase = Supabase.instance.client;
  List<Insumo> _insumos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarInsumos();
  }

  Future<void> _cargarInsumos() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('insumos').select().order('nombre');
      final lista = (response as List).map((e) => Insumo.fromMap(e)).toList();
      setState(() {
        _insumos = lista;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar insumos: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _mostrarFormularioAgregar() {
    final nombreCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    String unidad = 'ml';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuevo Insumo / Ingrediente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre (Ej: Vino Borgoña)',
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock Inicial',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: unidad,
                          items: const [
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(
                              value: 'unidades',
                              child: Text('unidades'),
                            ),
                            DropdownMenuItem(value: 'gr', child: Text('gr')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => unidad = val);
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: costoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Costo por unidad/ml',
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (nombreCtrl.text.isEmpty) return;
                        final stockInicial =
                            double.tryParse(stockCtrl.text) ?? 0.0;
                        final nuevoInsumo = Insumo(
                          nombre: nombreCtrl.text,
                          unidadMedida: unidad,
                          stockActual: stockInicial,
                          costoUnidad: double.tryParse(costoCtrl.text) ?? 0.0,
                        );

                        await _supabase
                            .from('insumos')
                            .insert(nuevoInsumo.toMap());

                        await AuditoriaService.registrarMovimiento(
                          usuario: widget.usuarioSesion,
                          tipoAccion: 'CREAR_INSUMO',
                          categoria: 'INVENTARIO',
                          descripcion:
                              'Creó el insumo "${nombreCtrl.text}" con stock inicial de $stockInicial $unidad',
                        );

                        if (mounted) Navigator.pop(context);
                        _cargarInsumos();
                      },
                      child: const Text('Guardar Insumo'),
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

  void _dialogoAjustarStock(Insumo insumo) {
    final cantCtrl = TextEditingController();
    bool esEntrada = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ajuste de Stock: ${insumo.nombre}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Entrada (+)'),
                          selected: esEntrada,
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(
                            color: esEntrada ? Colors.white : Colors.black,
                          ),
                          onSelected:
                              (val) => setDialogState(() => esEntrada = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Salida (-)'),
                          selected: !esEntrada,
                          selectedColor: Colors.red,
                          labelStyle: TextStyle(
                            color: !esEntrada ? Colors.white : Colors.black,
                          ),
                          onSelected:
                              (val) => setDialogState(() => esEntrada = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          'Cantidad a ${esEntrada ? "ingresar" : "retirar"} (${insumo.unidadMedida})',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (cantCtrl.text.isEmpty) return;
                    final cantidad = double.parse(cantCtrl.text);
                    final nuevoStock =
                        esEntrada
                            ? insumo.stockActual + cantidad
                            : insumo.stockActual - cantidad;

                    await _supabase
                        .from('insumos')
                        .update({'stock_actual': nuevoStock})
                        .eq('id', insumo.id!);

                    await AuditoriaService.registrarMovimiento(
                      usuario: widget.usuarioSesion,
                      tipoAccion: esEntrada ? 'ENTRADA_STOCK' : 'SALIDA_STOCK',
                      categoria: 'INVENTARIO',
                      descripcion:
                          esEntrada
                              ? 'Ingresó $cantidad ${insumo.unidadMedida} de "${insumo.nombre}" (Compra/Reposición)'
                              : 'Registró salida manual de $cantidad ${insumo.unidadMedida} de "${insumo.nombre}"',
                    );

                    if (mounted) Navigator.pop(context);
                    _cargarInsumos();
                  },
                  child: const Text('Guardar'),
                ),
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
      appBar: AppBar(title: const Text('Inventario de Insumos')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _insumos.isEmpty
              ? const Center(child: Text('No hay insumos registrados aún.'))
              : ListView.builder(
                itemCount: _insumos.length,
                itemBuilder: (context, index) {
                  final item = _insumos[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(item.unidadMedida)),
                    title: Text(item.nombre),
                    subtitle: Text(
                      'Stock: ${item.stockActual} ${item.unidadMedida}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _dialogoAjustarStock(item),
                        ),
                        Text('\$${item.costoUnidad}'),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioAgregar,
        child: const Icon(Icons.add),
      ),
    );
  }
}
