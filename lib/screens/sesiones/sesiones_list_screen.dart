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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Text('Nueva sesión'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: horarioId,
                decoration: const InputDecoration(labelText: 'Horario'),
                items: _horarios.map<DropdownMenuItem<int>>((h) => DropdownMenuItem(
                  value: h['id'] as int,
                  child: Text('${h['dia_semana']} ${h['hora_inicio']} — ${h['categoria_nombre']}',
                      overflow: TextOverflow.ellipsis),
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
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFFE65100), size: 18),
                      const SizedBox(width: 10),
                      Text('${fecha.day}/${fecha.month}/${fecha.year}',
                          style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Color _asistenciaColor(dynamic presentes, dynamic total) {
    final t = int.tryParse('$total') ?? 0;
    final p = int.tryParse('$presentes') ?? 0;
    if (t == 0) return Colors.grey;
    final pct = p / t;
    if (pct >= 0.8) return Colors.green;
    if (pct >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Sesiones de entrenamiento')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sesiones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_basketball, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No hay sesiones registradas',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _sesiones.length,
                      itemBuilder: (_, i) {
                        final s = _sesiones[i];
                        final presentes = int.tryParse('${s['presentes'] ?? 0}') ?? 0;
                        final total     = int.tryParse('${s['total_asistencias'] ?? 0}') ?? 0;
                        final color     = _asistenciaColor(presentes, total);
                        final pct       = total > 0
                            ? '${(presentes / total * 100).toStringAsFixed(0)}%'
                            : '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => RegistroAsistenciaScreen(sesion: s),
                              ));
                              _load();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE65100).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.sports_basketball, color: Color(0xFFE65100)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${s['categoria_nombre']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('${s['fecha']}  ·  ${s['dia_semana']} ${s['hora_inicio']}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$presentes/$total',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                                      Text(pct, style: TextStyle(fontSize: 12, color: color)),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
