import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});
  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _categorias = [];
  List _horarios   = [];
  bool _loading    = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await ApiService.get('/categorias') as List;
      final hors = await ApiService.get('/horarios')   as List;
      if (mounted) setState(() { _categorias = cats; _horarios = hors; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Color fijo por categoría (igual que jugadores) ──────────────────────
  static Color categoriaColor(String? cat) {
    const mapa = {
      'Sub-12':  Color(0xFF1565C0),
      'Sub-15':  Color(0xFF2E7D32),
      'Juvenil': Color(0xFF6A1B9A),
      'Senior':  Color(0xFF00838F),
    };
    if (cat == null) return const Color(0xFF1565C0);
    if (mapa.containsKey(cat)) return mapa[cat]!;
    const colores = [
      Color(0xFF1565C0), Color(0xFF2E7D32),
      Color(0xFF6A1B9A), Color(0xFF00838F),
      Color(0xFFE65100), Color(0xFFC62828),
    ];
    final hash = cat.codeUnits.fold(0, (a, b) => a * 31 + b);
    return colores[hash.abs() % colores.length];
  }

  // ── Ícono por día de semana ─────────────────────────────────────────────
  static IconData _diaIcon(String? dia) {
    switch (dia) {
      case 'Lunes':    return Icons.looks_one_rounded;
      case 'Martes':   return Icons.looks_two_rounded;
      case 'Miércoles':return Icons.looks_3_rounded;
      case 'Jueves':   return Icons.looks_4_rounded;
      case 'Viernes':  return Icons.looks_5_rounded;
      case 'Sábado':   return Icons.looks_6_rounded;
      default:         return Icons.calendar_today_rounded;
    }
  }

  // ── Diálogos (sin cambios en lógica) ───────────────────────────────────
  Future<void> _dialogCategoria([Map? cat]) async {
    final ctrl     = TextEditingController(text: cat?['nombre']      ?? '');
    final descCtrl = TextEditingController(text: cat?['descripcion'] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(cat == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctrl,     decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 8),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final body = {'nombre': ctrl.text.trim(), 'descripcion': descCtrl.text.trim()};
              try {
                cat == null
                    ? await ApiService.post('/categorias', body)
                    : await ApiService.put('/categorias/${cat['id']}', body);
                navigator.pop();
                if (mounted) _load();
              } on ApiException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategoria(int id) async {
    try {
      await ApiService.delete('/categorias/$id');
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _dialogHorario([Map? hor]) async {
    final dias = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    String dia      = hor?['dia_semana'] ?? dias[0];
    final inicioCtrl = TextEditingController(text: hor?['hora_inicio'] ?? '08:00');
    final finCtrl    = TextEditingController(text: hor?['hora_fin']    ?? '10:00');
    int? catId = hor != null
        ? hor['categoria_id'] as int
        : (_categorias.isNotEmpty ? _categorias[0]['id'] as int : null);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(hor == null ? 'Nuevo horario' : 'Editar horario'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: dia,
              decoration: const InputDecoration(labelText: 'Día'),
              items: dias.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setDlg(() => dia = v!),
            ),
            const SizedBox(height: 8),
            TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: 'Hora inicio (HH:MM)')),
            TextField(controller: finCtrl,    decoration: const InputDecoration(labelText: 'Hora fin (HH:MM)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: catId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _categorias.map<DropdownMenuItem<int>>((c) =>
                  DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre']))).toList(),
              onChanged: (v) => setDlg(() => catId = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final body = {
                  'dia_semana': dia,
                  'hora_inicio': inicioCtrl.text,
                  'hora_fin': finCtrl.text,
                  'categoria_id': catId,
                };
                try {
                  hor == null
                      ? await ApiService.post('/horarios', body)
                      : await ApiService.put('/horarios/${hor['id']}', body);
                  navigator.pop();
                  if (mounted) _load();
                } on ApiException catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHorario(int id) async {
    try {
      await ApiService.delete('/horarios/$id');
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Configuración'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Categorías'),
            Tab(text: 'Horarios'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCategorias(),
                _buildHorarios(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabCtrl.index == 0 ? _dialogCategoria() : _dialogHorario(),
        icon: const Icon(Icons.add),
        label: Text(_tabCtrl.index == 0 ? 'Nueva categoría' : 'Nuevo horario'),
      ),
    );
  }

  // ── Tab Categorías ──────────────────────────────────────────────────────
  Widget _buildCategorias() {
    if (_categorias.isEmpty) {
      return const _EmptyState(
        icon: Icons.category_rounded,
        message: 'No hay categorías registradas',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
      itemCount: _categorias.length,
      itemBuilder: (_, i) {
        final c     = _categorias[i];
        final color = categoriaColor(c['nombre'] as String?);
        final desc  = c['descripcion'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _dialogCategoria(c),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // Ícono de categoría con color
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.shield_rounded, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['nombre'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (desc != null && desc.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              desc,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Acciones
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: color, size: 20),
                      onPressed: () => _dialogCategoria(c),
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 20),
                      onPressed: () => _deleteCategoria(c['id']),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab Horarios ────────────────────────────────────────────────────────
  Widget _buildHorarios() {
    if (_horarios.isEmpty) {
      return const _EmptyState(
        icon: Icons.schedule_rounded,
        message: 'No hay horarios registrados',
      );
    }

    // Agrupar horarios por categoría
    final Map<String, List> grupos = {};
    for (final h in _horarios) {
      final key = h['categoria_nombre'] as String? ?? 'Sin categoría';
      grupos.putIfAbsent(key, () => []).add(h);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 100),
      children: grupos.entries.map((entry) {
        final catNombre = entry.key;
        final lista     = entry.value;
        final color     = categoriaColor(catNombre);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de grupo
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    catNombre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${lista.length} ${lista.length == 1 ? 'horario' : 'horarios'}',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Cards de horarios
            ...lista.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _dialogHorario(h),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_diaIcon(h['dia_semana'] as String?),
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h['dia_semana'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${h['hora_inicio']} - ${h['hora_fin']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_rounded, color: color, size: 18),
                          onPressed: () => _dialogHorario(h),
                          splashRadius: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red, size: 18),
                          onPressed: () => _deleteHorario(h['id']),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════════════════
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