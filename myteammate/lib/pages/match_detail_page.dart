import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MatchDetailPage extends StatefulWidget {
  final int matchId;

  const MatchDetailPage({super.key, required this.matchId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  Map<String, dynamic>? _match;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMatch();
  }

  Future<void> _fetchMatch() async {
    setState(() { _loading = true; _error = null; });
    final data = await AuthService.getMatchDetail(widget.matchId);
    if (!mounted) return;
    if (data == null) {
      setState(() { _loading = false; _error = 'Maç bilgileri yüklenemedi.'; });
    } else {
      setState(() { _loading = false; _match = data; });
    }
  }

  DateTime _parseDate(Map<String, dynamic> match) {
    final dateStr = match['date'] as String;
    final timeStr = match['time'] as String;
    final d = dateStr.split('-');
    final t = timeStr.split(':');
    return DateTime(
      int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
      int.parse(t[0]), int.parse(t[1]),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month]} - $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF4A8A3A)))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A8A3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildContent(_match!),

          // Geri butonu
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),

          // KATIL butonu
          if (_match != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildJoinButton(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> match) {
    final date      = _parseDate(match);
    final fieldName = match['fieldName'] as String;
    final district  = match['district'] as String? ?? '';
    final city      = match['city'] as String? ?? '';
    final current   = match['filledPlayers'] as int;
    final total     = match['requiredPlayers'] as int;
    final price     = (match['pricePerPerson'] as num).toDouble();
    final level     = match['skillLevel'] as String;
    final creator   = match['creatorName'] as String? ?? '—';
    final rating    = (match['creatorRating'] as num?)?.toDouble() ?? 0.0;
    final remaining = total - current;
    final isFull    = remaining <= 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldImage(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            child: Column(
              children: [
                _Card(
                  child: Text(
                    fieldName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(date),
                        style: const TextStyle(fontSize: 15, color: Color(0xFF2A2A2A)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF777777)),
                          const SizedBox(width: 4),
                          Text(
                            '$district, $city',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${price.toStringAsFixed(0)} ₺ / Kişi',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF2A2A2A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _Card(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFull ? 'KADRO DOLU' : '$remaining OYUNCU\nLAZIM',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _LevelBadge(level: level),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _GlowCircle(isFull: isFull, total: total, current: current),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _Card(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBBBBBB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Organizatör',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            creator,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.star, size: 18, color: Color(0xFF1A1A1A)),
                      const SizedBox(width: 4),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : '—',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    final current = _match!['filledPlayers'] as int;
    final total   = _match!['requiredPlayers'] as int;
    final isFull  = current >= total;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isFull ? null : () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A8A3A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFAAAAAA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          isFull ? 'DOLU' : 'KATIL',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
    );
  }
}

class _FieldImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Image.network(
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          color: const Color(0xFF1A3A0A),
          child: const Icon(Icons.sports_soccer, size: 64, color: Colors.white24),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  Color get _color {
    switch (level) {
      case 'Başlangıç':    return const Color(0xFF3A7A9A);
      case 'İleri Seviye': return const Color(0xFF2E5A1C);
      default:             return const Color(0xFF7A8A30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        level,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final bool isFull;
  final int total;
  final int current;

  const _GlowCircle({required this.isFull, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final color = isFull ? const Color(0xFFAAAAAA) : const Color(0xFF4A8A3A);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 16, spreadRadius: 4),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_soccer, color: Colors.white, size: 28),
            Text(
              '$current/$total',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
