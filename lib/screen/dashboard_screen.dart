import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import 'pos_screen.dart';
import 'insumos_screen.dart';
import 'productos_screen.dart';
import 'cierre_screen.dart';
import 'usuarios_screen.dart';
import 'historial_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Usuario usuarioSesion;

  const DashboardScreen({dynamic, required this.usuarioSesion});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = widget.usuarioSesion.rol == 'admin';

    final List<Widget> pantallas = [
      PosScreen(usuarioSesion: widget.usuarioSesion),
      InsumosScreen(usuarioSesion: widget.usuarioSesion),
      ProductosScreen(usuarioSesion: widget.usuarioSesion),
      CierreScreen(usuarioSesion: widget.usuarioSesion),
      if (esAdmin) HistorialScreen(),
      if (esAdmin) UsuariosScreen(usuarioSesion: widget.usuarioSesion),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Licorería - Hola, ${widget.usuarioSesion.nombre}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('Ventas (POS)')),
                const NavigationRailDestination(icon: Icon(Icons.inventory), label: Text('Insumos')),
                const NavigationRailDestination(icon: Icon(Icons.local_bar), label: Text('Tragos')),
                const NavigationRailDestination(icon: Icon(Icons.assessment), label: Text('Cierre/Arqueo')),
                if (esAdmin) const NavigationRailDestination(icon: Icon(Icons.history), label: Text('Historial')),
                if (esAdmin) const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Usuarios')),
              ],
            ),
          Expanded(child: pantallas[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.deepOrange,
              unselectedItemColor: Colors.grey,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Ventas'),
                const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Insumos'),
                const BottomNavigationBarItem(icon: Icon(Icons.local_bar), label: 'Tragos'),
                const BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Cierre'),
                if (esAdmin) const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
                if (esAdmin) const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
              ],
            )
          : null,
    );
  }
}