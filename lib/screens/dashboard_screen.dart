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
  int _categorias      = 0;
  int _jugadores       = 0;
  int _sesiones        = 0;
  List _ultimasSesiones = [];
  bool _loading        = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final cats = await ApiService.get('/categorias') as List;
      final jugs = await ApiService.get('/jugadores')  as List;
      final ses  = await ApiService.get('/sesiones')   as List;
      if (mounted) {
        setState(() {
          _categorias      = cats.length;
          _jugadores       = jugs.length;
          _sesiones        = ses.length;
          _ultimasSesiones = ses.take(3).toList();
          _loading         = false;
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

  String _fechaHoy() {
    const dias  = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio',
                   'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    final now = DateTime.now();
    final dia = dias[now.weekday - 1];
    return '${dia[0].toUpperCase()}${dia.substring(1)}, ${now.day} de ${meses[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre  = usuario?['nombre'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: _loading
          ? _buildSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFE65100),
              child: CustomScrollView(
                slivers: [
                  _buildHeader(nombre),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),
                        _buildStats(),
                        const SizedBox(height: 28),
                        _buildQuickActions(),
                        if (_ultimasSesiones.isNotEmpty) ...[
                          const SizedBox(height: 28),
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

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFBF360C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(3, (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: CircularProgressIndicator(color: Color(0xFFE65100)),
        ),
      ],
    );
  }

  Widget _buildHeader(String nombre) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFFE65100),
      elevation: 0,
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
              colors: [Color(0xFFE65100), Color(0xFF8D1F00)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, top: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 40, bottom: -20,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_basketball,
                              color: Colors.white60, size: 16),
                          const SizedBox(width: 6),
                          Text(_fechaHoy(),
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Hola, $nombre 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          )),
                      const SizedBox(height: 4),
                      const Text('Control de Asistencia Deportiva',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(label: 'Categorías', value: _categorias,
            icon: Icons.category_rounded,   color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _StatCard(label: 'Jugadores',  value: _jugadores,
            icon: Icons.people_rounded,     color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        _StatCard(label: 'Sesiones',   value: _sesiones,
            icon: Icons.event_note_rounded, color: const Color(0xFFE65100)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Accesos rápidos'),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionCard(
              icon: Icons.people_rounded,
              label: 'Jugadores',
              subtitle: 'Ver plantel',
              color: const Color(0xFF1565C0),
              onTap: () => widget.onNavigate?.call(1),
            ),
            const SizedBox(width: 12),
            _ActionCard(
              icon: Icons.sports_basketball_rounded,
              label: 'Sesiones',
              subtitle: 'Entrenamientos',
              color: const Color(0xFF2E7D32),
              onTap: () => widget.onNavigate?.call(2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionCardWide(
          icon: Icons.tune_rounded,
          label: 'Configuración',
          subtitle: 'Categorías y ajustes del sistema',
          color: const Color(0xFFE65100),
          onTap: () => widget.onNavigate?.call(3),
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
            const _SectionTitle(title: 'Últimas sesiones'),
            TextButton(
              onPressed: () => widget.onNavigate?.call(2),
              child: const Text('Ver todas',
                  style: TextStyle(color: Color(0xFFE65100))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._ultimasSesiones.map((s) => _SesionTile(sesion: s)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers globales de formato
// ═══════════════════════════════════════════════════════════════════════════
class DashboardHelpers {
  static String formatFecha(String? raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw);
      const meses = ['ene','feb','mar','abr','may','jun',
                     'jul','ago','sep','oct','nov','dic'];
      return '${d.day} ${meses[d.month - 1]} ${d.year}';
    } catch (_) { return raw; }
  }

  static String formatHora(String? raw) {
    if (raw == null) return '';
    try {
      final parts = raw.split(':');
      int h   = int.parse(parts[0]);
      final m = parts[1];
      final ampm = h >= 12 ? 'PM' : 'AM';
      h = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$h:$m $ampm';
    } catch (_) { return raw; }
  }

  static Color catColor(String? cat) {
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
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets internos
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE65100),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text('$value', style: TextStyle(fontSize: 28,
                fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCardWide extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCardWide({required this.icon, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Tile de sesión ─────────────────────────────────────────────────────────
class _SesionTile extends StatelessWidget {
  final Map sesion;
  const _SesionTile({required this.sesion});

  @override
  Widget build(BuildContext context) {
    final presentes = int.tryParse('${sesion['presentes'] ?? 0}') ?? 0;
    final total     = int.tryParse('${sesion['total_asistencias'] ?? 0}') ?? 0;
    final pct       = total > 0 ? presentes / total : 0.0;

    final Color statusColor = pct >= 0.8
        ? const Color(0xFF2E7D32)
        : pct >= 0.5
            ? const Color(0xFFF57C00)
            : const Color(0xFFC62828);

    final categoria = sesion['categoria_nombre'] as String?;
    final color     = DashboardHelpers.catColor(categoria);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sports_basketball_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(categoria ?? '',
                              style: TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600, color: color)),
                        ),
                        const SizedBox(width: 6),
                        Text(sesion['dia_semana'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          DashboardHelpers.formatFecha(sesion['fecha'] as String?),
                          style: TextStyle(fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          DashboardHelpers.formatHora(sesion['hora_inicio'] as String?),
                          style: TextStyle(fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$presentes/$total',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: statusColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      total > 0 ? '${(pct * 100).toStringAsFixed(0)}%' : '—',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}