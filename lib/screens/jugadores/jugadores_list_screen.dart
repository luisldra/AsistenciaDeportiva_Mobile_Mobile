import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'jugador_form_screen.dart';

class JugadoresListScreen extends StatefulWidget {
  const JugadoresListScreen({super.key});
  @override
  State<JugadoresListScreen> createState() => _JugadoresListScreenState();
}

class _JugadoresListScreenState extends State<JugadoresListScreen> {
  List _jugadores = [];
  List _categorias = [];
  int? _categoriaFiltro;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await ApiService.get('/categorias') as List;
      final path = _categoriaFiltro != null ? '/jugadores?categoria_id=$_categoriaFiltro' : '/jugadores';
      final jugs = await ApiService.get(path) as List;
      if (mounted) setState(() {
      final seen = <dynamic>{};
      _categorias = cats.where((c) => seen.add(c['id'])).toList();
      _jugadores  = List.from(jugs);
      _loading    = false;
    });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar jugador'),
        content: Text('¿Eliminar a $nombre? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.delete('/jugadores/$id');
        _load();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Jugadores'),
        bottom: _categorias.isEmpty ? null : PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: const Color(0xFFE65100),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    selected: _categoriaFiltro == null,
                    onTap: () { setState(() => _categoriaFiltro = null); _load(); },
                  ),
                  ..._categorias.map((c) => _FilterChip(
                    label: c['nombre'],
                    selected: _categoriaFiltro == c['id'],
                    onTap: () { setState(() => _categoriaFiltro = c['id'] as int); _load(); },
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _jugadores.isEmpty
                  ? const _EmptyState(icon: Icons.people_outline, message: 'No hay jugadores registrados')
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _jugadores.length,
                      itemBuilder: (_, i) {
                        final j = _jugadores[i];
                        return _JugadorCard(
                          jugador: j,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => JugadorFormScreen(jugador: j),
                            ));
                            _load();
                          },
                          onDelete: () => _delete(j['id'], '${j['nombre']} ${j['apellido']}'),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const JugadorFormScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo jugador'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? const Color(0xFFE65100) : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _JugadorCard extends StatelessWidget {
  final Map jugador;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _JugadorCard({required this.jugador, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final numero = jugador['numero'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE65100),
          child: Text(numero != null ? '$numero' : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text('${jugador['nombre']} ${jugador['apellido']}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            const Icon(Icons.category, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text(jugador['categoria_nombre'] ?? '', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}
