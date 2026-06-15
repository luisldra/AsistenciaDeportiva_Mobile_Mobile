import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'jugador_form_screen.dart';

class JugadoresListScreen extends StatefulWidget {
  const JugadoresListScreen({super.key});
  @override
  State<JugadoresListScreen> createState() => _JugadoresListScreenState();
}

class _JugadoresListScreenState extends State<JugadoresListScreen> {
  List _jugadores   = [];
  List _categorias  = [];
  int? _categoriaFiltro;
  bool _loading     = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await ApiService.get('/categorias') as List;
      final path = _categoriaFiltro != null
          ? '/jugadores?categoria_id=$_categoriaFiltro'
          : '/jugadores';
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

  List get _jugadoresFiltrados {
    if (_searchQuery.isEmpty) return _jugadores;
    return _jugadores.where((j) {
      final nombre = '${j['nombre']} ${j['apellido']}'.toLowerCase();
      return nombre.contains(_searchQuery);
    }).toList();
  }

  Future<void> _delete(int id, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar jugador'),
        content: Text('¿Eliminar a $nombre? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jugadoresMostrar = _jugadoresFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Jugadores'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_categorias.isEmpty ? 56 : 108),
          child: Column(
            children: [
              // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar jugador...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFFE65100), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
              // Chips de categoría
              if (_categorias.isNotEmpty)
                Container(
                  color: const Color(0xFFE65100),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                          onTap: () {
                            setState(() => _categoriaFiltro = c['id'] as int);
                            _load();
                          },
                        )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFE65100),
              child: jugadoresMostrar.isEmpty
                  ? _EmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off
                          : Icons.people_outline,
                      message: _searchQuery.isNotEmpty
                          ? 'No se encontró "$_searchQuery"'
                          : 'No hay jugadores registrados',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: jugadoresMostrar.length,
                      itemBuilder: (_, i) {
                        final j = jugadoresMostrar[i];
                        return _JugadorCard(
                          jugador: j,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JugadorFormScreen(jugador: j),
                              ),
                            );
                            _load();
                          },
                          onDelete: () => _delete(
                            j['id'],
                            '${j['nombre']} ${j['apellido']}',
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JugadorFormScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo jugador'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Componentes
// ═══════════════════════════════════════════════════════════════════════════

// ── Chip de filtro ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFE65100) : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Card de jugador ───────────────────────────────────────────────────────
class _JugadorCard extends StatelessWidget {
  final Map jugador;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _JugadorCard({
    required this.jugador,
    required this.onTap,
    required this.onDelete,
  });

  // Genera un color único por categoría
  Color _categoriaColor(String? cat) {
    const mapa = {
      'Sub-12':  Color(0xFF1565C0), // azul
      'Sub-15':  Color(0xFF2E7D32), // verde
      'Juvenil': Color(0xFF6A1B9A), // morado
      'Senior':  Color(0xFF00838F), // teal
    };
    if (cat == null) return const Color(0xFF1565C0);
    // Busca coincidencia exacta primero, si no usa hash
    if (mapa.containsKey(cat)) return mapa[cat]!;
    const colores = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFE65100),
      Color(0xFFC62828),
    ];
    final hash = cat.codeUnits.fold(0, (a, b) => a * 31 + b);
    return colores[hash.abs() % colores.length];
  }

  // Iniciales del jugador
  String _iniciales(String nombre, String apellido) {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$n$a';
  }

  @override
  Widget build(BuildContext context) {
    final nombre    = jugador['nombre']   as String? ?? '';
    final apellido  = jugador['apellido'] as String? ?? '';
    final numero    = jugador['numero'];
    final categoria = jugador['categoria_nombre'] as String?;
    final posicion  = jugador['posicion']  as String?;
    final catColor  = _categoriaColor(categoria);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar con iniciales
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _iniciales(nombre, apellido),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                      ),
                    ),
                    // Número del jugador
                    if (numero != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: catColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$numero',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Info del jugador
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$nombre $apellido',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Badge categoría
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria ?? 'Sin categoría',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                          ),
                          if (posicion != null && posicion.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· $posicion',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón eliminar
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}