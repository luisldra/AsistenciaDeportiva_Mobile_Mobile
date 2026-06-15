import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../asistencia/registro_asistencia_screen.dart';

class SesionesListScreen extends StatefulWidget {
  const SesionesListScreen({super.key});
  @override
  State<SesionesListScreen> createState() => _SesionesListScreenState();
}

class _SesionesListScreenState extends State<SesionesListScreen> {
  List _sesiones = [];
  List _horarios = [];
  bool _loading  = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ses = await ApiService.get('/sesiones') as List;
      final hor = await ApiService.get('/horarios') as List;
      if (mounted) setState(() { _sesiones = ses; _horarios = hor; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  // Color por categoría (igual que jugadores y configuración)
  static Color _catColor(String? cat) {
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

  // Formatea "2026-06-15" → "15 jun 2026"
  static String _formatFecha(String? raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw);
      const meses = ['ene','feb','mar','abr','may','jun',
                     'jul','ago','sep','oct','nov','dic'];
      return '${d.day} ${meses[d.month - 1]} ${d.year}';
    } catch (_) { return raw; }
  }

  // Formatea "08:00:00" → "8:00 AM"
  static String _formatHora(String? raw) {
    if (raw == null) return '';
    try {
      final parts = raw.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1];
      final ampm = h >= 12 ? 'PM' : 'AM';
      h = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$h:$m $ampm';
    } catch (_) { return raw; }
  }

  Color _asistenciaColor(int presentes, int total) {
    if (total == 0) return Colors.grey;
    final pct = presentes / total;
    if (pct >= 0.8) return const Color(0xFF2E7D32);
    if (pct >= 0.5) return const Color(0xFFF57C00);
    return const Color(0xFFC62828);
  }

  Future<void> _crearSesion() async {
    if (_horarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea un horario primero en Configuración')),
      );
      return;
    }
    int? horarioId = _horarios[0]['id'];
    DateTime fecha = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.add_circle_outline, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Text('Nueva sesión'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: horarioId,
              decoration: const InputDecoration(labelText: 'Horario'),
              items: _horarios.map<DropdownMenuItem<int>>((h) => DropdownMenuItem(
                value: h['id'] as int,
                child: Text(
                  '${h['dia_semana']} ${_formatHora(h['hora_inicio'])} — ${h['categoria_nombre']}',
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: (v) => setDlg(() => horarioId = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) setDlg(() => fecha = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 10),
                  Text(_formatFecha(fecha.toIso8601String().split('T')[0]),
                      style: const TextStyle(fontSize: 15)),
                ]),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                try {
                  await ApiService.post('/sesiones', {
                    'fecha': fecha.toIso8601String().split('T')[0],
                    'horario_id': horarioId,
                  });
                  navigator.pop();
                  if (mounted) _load();
                } on ApiException catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: const Text('Sesiones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFE65100),
              child: _sesiones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sports_basketball_rounded,
                                size: 48, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text('No hay sesiones registradas',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: _sesiones.length,
                      itemBuilder: (_, i) => _SesionCard(
                        sesion:    _sesiones[i],
                        catColor:  _catColor(_sesiones[i]['categoria_nombre'] as String?),
                        formatFecha: _formatFecha,
                        formatHora:  _formatHora,
                        asistenciaColor: _asistenciaColor,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => RegistroAsistenciaScreen(sesion: _sesiones[i]),
                          ));
                          _load();
                        },
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearSesion,
        icon: const Icon(Icons.add),
        label: const Text('Nueva sesión'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Card de sesión
// ═══════════════════════════════════════════════════════════════════════════
class _SesionCard extends StatelessWidget {
  final Map sesion;
  final Color catColor;
  final String Function(String?) formatFecha;
  final String Function(String?) formatHora;
  final Color Function(int, int) asistenciaColor;
  final VoidCallback onTap;

  const _SesionCard({
    required this.sesion,
    required this.catColor,
    required this.formatFecha,
    required this.formatHora,
    required this.asistenciaColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final presentes = int.tryParse('${sesion['presentes'] ?? 0}') ?? 0;
    final total     = int.tryParse('${sesion['total_asistencias'] ?? 0}') ?? 0;
    final pct       = total > 0 ? presentes / total : 0.0;
    final color     = asistenciaColor(presentes, total);
    final pctLabel  = total > 0 ? '${(pct * 100).toStringAsFixed(0)}%' : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.08),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    // Ícono con color de categoría
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.sports_basketball_rounded,
                          color: catColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge categoría + día
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  sesion['categoria_nombre'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sesion['dia_semana'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Fecha y hora formateadas
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                formatFecha(sesion['fecha'] as String?),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time_rounded,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                formatHora(sesion['hora_inicio'] as String?),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Asistencia
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$presentes/$total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pctLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 10),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}