import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegistroAsistenciaScreen extends StatefulWidget {
  final Map sesion;
  const RegistroAsistenciaScreen({super.key, required this.sesion});
  @override
  State<RegistroAsistenciaScreen> createState() => _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState extends State<RegistroAsistenciaScreen> {
  List _jugadores = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/sesiones/${widget.sesion['id']}/asistencia');
      if (mounted) setState(() { _jugadores = List.from(data['jugadores']); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _marcarTodos(bool presente) {
    setState(() {
      for (final j in _jugadores) {
        j['presente'] = presente;
        if (!presente) j['llegada_tarde'] = false;
      }
    });
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      await ApiService.post('/sesiones/${widget.sesion['id']}/asistencia', {
        'asistencias': _jugadores.map((j) => {
          'jugador_id': j['jugador_id'],
          'presente': j['presente'],
          'llegada_tarde': j['llegada_tarde'],
        }).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistencia guardada correctamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int get _presentes => _jugadores.where((j) => j['presente'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asistencia', style: TextStyle(fontSize: 18)),
            Text('${widget.sesion['fecha']} — ${widget.sesion['categoria_nombre'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _saving ? null : _guardar,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jugadores.isEmpty
              ? const Center(child: Text('No hay jugadores en esta categoría'))
              : Column(
                  children: [
                    _buildResumen(),
                    _buildAcciones(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: _jugadores.length,
                        itemBuilder: (_, i) => _JugadorAsistenciaTile(
                          jugador: _jugadores[i],
                          onPresente: (v) => setState(() {
                            _jugadores[i]['presente'] = v;
                            if (!v) _jugadores[i]['llegada_tarde'] = false;
                          }),
                          onTarde: (v) => setState(() => _jugadores[i]['llegada_tarde'] = v),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildResumen() {
    final total = _jugadores.length;
    final ausentes = total - _presentes;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ResumenItem(label: 'Total', value: '${_jugadores.length}', color: Colors.grey.shade700),
          _ResumenItem(label: 'Presentes', value: '$_presentes', color: Colors.green),
          _ResumenItem(label: 'Ausentes', value: '$ausentes', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _marcarTodos(true),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Todos presentes'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _marcarTodos(false),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Todos ausentes'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResumenItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _JugadorAsistenciaTile extends StatelessWidget {
  final Map jugador;
  final ValueChanged<bool> onPresente;
  final ValueChanged<bool> onTarde;
  const _JugadorAsistenciaTile({required this.jugador, required this.onPresente, required this.onTarde});

  @override
  Widget build(BuildContext context) {
    final presente    = jugador['presente'] as bool;
    final tarde       = jugador['llegada_tarde'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: presente ? Colors.green : Colors.red,
              radius: 22,
              child: Text('${jugador['numero'] ?? '?'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${jugador['nombre']} ${jugador['apellido']}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (tarde)
                    const Text('Llegó tarde', style: TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              ),
            ),
            Row(
              children: [
                _ToggleBtn(
                  icon: Icons.check,
                  label: 'Pres.',
                  active: presente,
                  activeColor: Colors.green,
                  onTap: () => onPresente(!presente),
                ),
                const SizedBox(width: 6),
                _ToggleBtn(
                  icon: Icons.access_time,
                  label: 'Tarde',
                  active: tarde,
                  activeColor: Colors.orange,
                  onTap: presente ? () => onTarde(!tarde) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;
  const _ToggleBtn({required this.icon, required this.label, required this.active, required this.activeColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? activeColor : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: active ? activeColor : Colors.grey),
            Text(label, style: TextStyle(fontSize: 10, color: active ? activeColor : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
