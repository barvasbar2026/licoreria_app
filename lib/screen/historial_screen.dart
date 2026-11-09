import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _movimientos = [];
  bool _isLoading = true;
  String _filtroCategoria = 'TODOS';

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('movimientos')
          .select()
          .order('created_at', ascending: false);

      final res = await query;
      setState(() {
        _movimientos = List<dynamic>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Color _obtenerColor(String tipo) {
    if (tipo.contains('VENTA')) return Colors.green;
    if (tipo.contains('ENTRADA')) return Colors.teal;
    if (tipo.contains('SALIDA')) return Colors.deepOrange;
    if (tipo.contains('ARQUEO')) return Colors.amber.shade800;
    if (tipo.contains('USUARIO')) return Colors.purple;
    return Colors.blue;
  }

  IconData _obtenerIcono(String tipo) {
    if (tipo.contains('VENTA')) return Icons.point_of_sale;
    if (tipo.contains('ENTRADA')) return Icons.add_box;
    if (tipo.contains('SALIDA')) return Icons.indeterminate_check_box;
    if (tipo.contains('ARQUEO')) return Icons.assessment;
    if (tipo.contains('USUARIO')) return Icons.person;
    return Icons.settings;
  }

  @override
  Widget build(BuildContext context) {
    final movimientosFiltrados =
        _filtroCategoria == 'TODOS'
            ? _movimientos
            : _movimientos
                .where((m) => m['categoria'] == _filtroCategoria)
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kárdex & Historial de Movimientos'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMovimientos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children:
                  [
                    'TODOS',
                    'VENTAS',
                    'INVENTARIO',
                    'USUARIOS',
                    'CONFIGURACION',
                  ].map((cat) {
                    final isSelected = _filtroCategoria == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Colors.deepOrange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _filtroCategoria = cat);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Lista de Movimientos
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : movimientosFiltrados.isEmpty
                    ? const Center(
                      child: Text('No hay registros en este filtro.'),
                    )
                    : ListView.builder(
                      itemCount: movimientosFiltrados.length,
                      itemBuilder: (context, index) {
                        final item = movimientosFiltrados[index];
                        final fecha =
                            DateTime.parse(item['created_at']).toLocal();
                        final fechaStr =
                            '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
                        final tipo = item['tipo_accion'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _obtenerColor(tipo),
                              child: Icon(
                                _obtenerIcono(tipo),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              item['descripcion'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Usuario: ${item['nombre_usuario']} | Cat: ${item['categoria']}',
                            ),
                            trailing: Text(
                              fechaStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
