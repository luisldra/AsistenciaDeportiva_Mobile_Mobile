import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _categorias = 0;
  int _jugadores = 0;
  int _sesiones = 0;
  List _ultimasSesiones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await ApiService.get('/categorias') as List;
      final jugs = await ApiService.get('/jugadores') as List;
      final ses  = await ApiService.get('/sesiones')  as List;
      if (mounted) {
        setState(() {
          _categorias = cats.length;
          _jugadores  = jugs.length;
          _sesiones   = ses.length;
          _ultimasSesiones = ses.take(3).toList();
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        await context.read<AuthProvider>().logout();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre  = usuario?['nombre'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(nombre),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),
                        _buildStats(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        if (_ultimasSesiones.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildUltimasSesiones(),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String nombre) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFFE65100),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Cerrar sesión',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE65100), Color(0xFFBF360C)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_basketball, color: Colors.white70, size: 20),
                      const SizedBox(width: 6),
                      const Text('Control de Asistencia',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Hola, $nombre 👋',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(label: 'Categorías', value: _categorias,
            icon: Icons.category, color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _StatCard(label: 'Jugadores', value: _jugadores,
            icon: Icons.people, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        _StatCard(label: 'Sesiones', value: _sesiones,
            icon: Icons.calendar_today, color: const Color(0xFFE65100)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Accesos rápidos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF212121))),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionTile(
              icon: Icons.people,
              label: 'Jugadores',
              color: const Color(0xFF1565C0),
              onTap: () => widget.onNavigate?.call(1),
            ),
            const SizedBox(width: 12),
            _ActionTile(
              icon: Icons.sports_basketball,
              label: 'Sesiones',
              color: const Color(0xFF2E7D32),
              onTap: () => widget.onNavigate?.call(2),
            ),
            const SizedBox(width: 12),
            _ActionTile(
              icon: Icons.settings,
              label: 'Config',
              color: const Color(0xFFE65100),
              onTap: () => widget.onNavigate?.call(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUltimasSesiones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Últimas sesiones',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF212121))),
            TextButton(
              onPressed: () => widget.onNavigate?.call(2),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._ultimasSesiones.map((s) => _SesionTile(sesion: s)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withValues(alpha:0.35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SesionTile extends StatelessWidget {
  final Map sesion;
  const _SesionTile({required this.sesion});

  @override
  Widget build(BuildContext context) {
    final presentes = int.tryParse('${sesion['presentes'] ?? 0}') ?? 0;
    final total     = int.tryParse('${sesion['total_asistencias'] ?? 0}') ?? 0;
    final pct       = total > 0 ? presentes / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_basketball, color: Color(0xFFE65100), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${sesion['categoria_nombre']} — ${sesion['dia_semana']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${sesion['fecha']}  ·  ${sesion['hora_inicio']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$presentes/$total',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 12,
                      color: pct >= 0.8 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}
