import 'package:flutter/material.dart';
import 'package:licoreria_app/models/auditoria_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/insumo_model.dart';
import '../models/usuario_model.dart';


class CierreScreen extends StatefulWidget {
  final Usuario usuarioSesion;

  const CierreScreen({super.key, required this.usuarioSesion});

  @override
  State<CierreScreen> createState() => _CierreScreenState();
}

class _CierreScreenState extends State<CierreScreen> {
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
      final res = await _supabase.from('insumos').select().order('nombre');
      final lista = (res as List).map((e) => Insumo.fromMap(e)).toList();
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

  void _mostrarDialogoArqueo(Insumo insumo) {
    final stockRealCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Arqueo: ${insumo.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Teórico (Sistema): ${insumo.stockActual} ${insumo.unidadMedida}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: stockRealCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Stock Real Medido (${insumo.unidadMedida})',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN de Autorización Admin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (stockRealCtrl.text.isEmpty || pinCtrl.text.isEmpty) return;

                final userRes =
                    await _supabase
                        .from('usuarios')
                        .select()
                        .eq('pin_autorizacion', pinCtrl.text.trim())
                        .eq('rol', 'admin')
                        .maybeSingle();

                if (userRes == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIN de autorización incorrecto'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final adminUser = Usuario.fromMap(userRes);
                final stockTeorico = insumo.stockActual;
                final stockReal = double.parse(stockRealCtrl.text);
                final diferencia = stockReal - stockTeorico;

                await _supabase.from('cierres_inventario').insert({
                  'insumo_id': insumo.id,
                  'stock_teorico': stockTeorico,
                  'stock_real': stockReal,
                  'diferencia': diferencia,
                  'usuario_autoriza_id': adminUser.id,
                  'observaciones': obsCtrl.text,
                });

                await _supabase
                    .from('insumos')
                    .update({'stock_actual': stockReal})
                    .eq('id', insumo.id!);

                await AuditoriaService.registrarMovimiento(
                  usuario: adminUser,
                  tipoAccion: 'ARQUEO',
                  categoria: 'INVENTARIO',
                  descripcion:
                      'Ajustó stock de "${insumo.nombre}". Teórico: $stockTeorico | Real: $stockReal (Dif: $diferencia)',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _cargarInsumos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Arqueo registrado. Diferencia: $diferencia ${insumo.unidadMedida}',
                      ),
                      backgroundColor:
                          diferencia < 0 ? Colors.orange : Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Guardar Arqueo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Inventario / Arqueo'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _insumos.length,
                itemBuilder: (context, index) {
                  final insumo = _insumos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      title: Text(
                        insumo.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Stock Teórico: ${insumo.stockActual} ${insumo.unidadMedida}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _mostrarDialogoArqueo(insumo),
                        child: const Text('Realizar Arqueo'),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
