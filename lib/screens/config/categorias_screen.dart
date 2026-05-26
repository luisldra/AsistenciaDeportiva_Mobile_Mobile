import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});
  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _categorias = [];
  List _horarios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await ApiService.get('/categorias') as List;
      final hors = await ApiService.get('/horarios') as List;
      if (mounted) setState(() { _categorias = cats; _horarios = hors; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dialogCategoria([Map? cat]) async {
    final ctrl = TextEditingController(text: cat?['nombre'] ?? '');
    final descCtrl = TextEditingController(text: cat?['descripcion'] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cat == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre')),
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
                if (cat == null) {
                  await ApiService.post('/categorias', body);
                } else {
                  await ApiService.put('/categorias/${cat['id']}', body);
                }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _dialogHorario([Map? hor]) async {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    String dia = hor?['dia_semana'] ?? dias[0];
    final inicioCtrl = TextEditingController(text: hor?['hora_inicio'] ?? '08:00');
    final finCtrl = TextEditingController(text: hor?['hora_fin'] ?? '10:00');
    int? catId = hor != null ? hor['categoria_id'] as int : (_categorias.isNotEmpty ? _categorias[0]['id'] as int : null);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
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
            TextField(controller: finCtrl, decoration: const InputDecoration(labelText: 'Hora fin (HH:MM)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: catId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _categorias.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre']))).toList(),
              onChanged: (v) => setDlg(() => catId = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final body = {'dia_semana': dia, 'hora_inicio': inicioCtrl.text, 'hora_fin': finCtrl.text, 'categoria_id': catId};
                try {
                  if (hor == null) {
                    await ApiService.post('/horarios', body);
                  } else {
                    await ApiService.put('/horarios/${hor['id']}', body);
                  }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        bottom: TabBar(controller: _tabCtrl, tabs: const [Tab(text: 'Categorías'), Tab(text: 'Horarios')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab Categorías
                _categorias.isEmpty
                    ? const Center(child: Text('No hay categorías'))
                    : ListView.builder(
                        itemCount: _categorias.length,
                        itemBuilder: (_, i) {
                          final c = _categorias[i];
                          return ListTile(
                            title: Text(c['nombre']),
                            subtitle: c['descripcion'] != null ? Text(c['descripcion']) : null,
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _dialogCategoria(c)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategoria(c['id'])),
                            ]),
                          );
                        },
                      ),
                // Tab Horarios
                _horarios.isEmpty
                    ? const Center(child: Text('No hay horarios'))
                    : ListView.builder(
                        itemCount: _horarios.length,
                        itemBuilder: (_, i) {
                          final h = _horarios[i];
                          return ListTile(
                            leading: const Icon(Icons.access_time, color: Colors.orange),
                            title: Text('${h['dia_semana']} ${h['hora_inicio']} - ${h['hora_fin']}'),
                            subtitle: Text(h['categoria_nombre'] ?? ''),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _dialogHorario(h)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHorario(h['id'])),
                            ]),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabCtrl.index == 0 ? _dialogCategoria() : _dialogHorario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
