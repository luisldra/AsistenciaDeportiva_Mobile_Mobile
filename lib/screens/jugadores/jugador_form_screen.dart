import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class JugadorFormScreen extends StatefulWidget {
  final Map? jugador;
  const JugadorFormScreen({super.key, this.jugador});
  @override
  State<JugadorFormScreen> createState() => _JugadorFormScreenState();
}

class _JugadorFormScreenState extends State<JugadorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  List _categorias = [];
  List _historial = [];
  int? _categoriaId;
  DateTime? _fechaNac;
  bool _loading = false;
  bool _loadingData = true;

  bool get _isEditing => widget.jugador != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nombreCtrl.text = widget.jugador!['nombre'] ?? '';
      _apellidoCtrl.text = widget.jugador!['apellido'] ?? '';
      _numeroCtrl.text = '${widget.jugador!['numero'] ?? ''}';
      _categoriaId = widget.jugador!['categoria_id'];
      final fn = widget.jugador!['fecha_nac'];
      if (fn != null) _fechaNac = DateTime.tryParse(fn);
    }
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await ApiService.get('/categorias') as List;
      List hist = [];
      if (_isEditing) {
        hist = await ApiService.get('/jugadores/${widget.jugador!['id']}/asistencia') as List;
      }
      if (mounted) setState(() { _categorias = cats; _historial = hist; _loadingData = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _numeroCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _fechaNac = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }
    setState(() => _loading = true);
    final body = {
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'numero': int.tryParse(_numeroCtrl.text) ?? 0,
      'categoria_id': _categoriaId,
      if (_fechaNac != null) 'fecha_nac': _fechaNac!.toIso8601String().split('T')[0],
    };
    try {
      if (_isEditing) {
        await ApiService.put('/jugadores/${widget.jugador!['id']}', body);
      } else {
        await ApiService.post('/jugadores', body);
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar jugador' : 'Nuevo jugador')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _numeroCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Número de camiseta'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _categoriaId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _categorias.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre']))).toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                      validator: (v) => v == null ? 'Selecciona una categoría' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_fechaNac == null ? 'Fecha de nacimiento (opcional)' : 'Nacimiento: ${_fechaNac!.day}/${_fechaNac!.month}/${_fechaNac!.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading ? const CircularProgressIndicator() : Text(_isEditing ? 'Guardar cambios' : 'Crear jugador'),
                    ),
                    if (_isEditing && _historial.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Historial de asistencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ..._historial.map((h) => ListTile(
                        leading: Icon(
                          h['presente'] == true ? Icons.check_circle : Icons.cancel,
                          color: h['presente'] == true ? Colors.green : Colors.red,
                        ),
                        title: Text('${h['fecha']}'),
                        subtitle: Text('${h['dia_semana']} ${h['hora_inicio']}${h['llegada_tarde'] == true ? ' (tarde)' : ''}'),
                      )),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
