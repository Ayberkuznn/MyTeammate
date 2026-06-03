import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'evaluate_match_page.dart';
import 'match_detail_page.dart';

class MyMatchesPage extends StatefulWidget {
  const MyMatchesPage({super.key});

  @override
  State<MyMatchesPage> createState() => _MyMatchesPageState();
}

class _MyMatchesPageState extends State<MyMatchesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _past = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    final data = await AuthService.getMyMatches();
    if (!mounted) return;

    if (data == null) {
      setState(() { _loading = false; _error = 'Maçlar yüklenemedi.'; });
      return;
    }

    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];
    final past = <Map<String, dynamic>>[];

    for (final m in data) {
      final dt = _parseDate(m);
      if (dt.isAfter(now)) {
        upcoming.add(m);
      } else {
        past.add(m);
      }
    }

    setState(() {
      _upcoming = upcoming;
      _past = past;
      _loading = false;
    });
  }

  DateTime _parseDate(Map<String, dynamic> m) {
    final d = (m['date'] as String).split('-');
    final t = (m['time'] as String).split(':');
    return DateTime(
      int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
      int.parse(t[0]), int.parse(t[1]),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month]} – $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Maçlarım',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A7A3A),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A5A1A),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF6AAA3A),
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFB8D8A0),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(text: 'YAKLAŞAN'),
                  Tab(text: 'GEÇMİŞ'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4A7A4A)))
                  : _error != null
                      ? _buildError()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(_upcoming, upcoming: true),
                            _buildList(_past, upcoming: false),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!,
              style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchMatches,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7A4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRateOrganizerDialog(int matchId) async {
    int selected = 0;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Organizatörü Değerlendir',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setS(() => selected = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= selected ? Icons.star : Icons.star_border,
                    color: star <= selected
                        ? const Color(0xFFE0A820)
                        : const Color(0xFFCCCCCC),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal',
                  style: TextStyle(color: Color(0xFF8A8A8A))),
            ),
            ElevatedButton(
              onPressed: selected == 0
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final result =
                          await AuthService.rateOrganizer(matchId, selected);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.success
                              ? 'Değerlendirme kaydedildi!'
                              : (result.error ?? 'Bir hata oluştu.')),
                          backgroundColor: result.success
                              ? const Color(0xFF4A8A3A)
                              : const Color(0xFFAA3A3A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      if (result.success) _fetchMatches();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7A4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> matches, {required bool upcoming}) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          upcoming
              ? 'Yaklaşan maçın bulunmuyor.'
              : 'Geçmiş maçın bulunmuyor.',
          style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF4A7A4A),
      onRefresh: _fetchMatches,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final m            = matches[i];
          final isCreator    = m['isCreator'] as bool? ?? false;
          final isEvaluated  = m['isEvaluated'] as bool? ?? false;
          final isRated      = m['isRated'] as bool? ?? false;
          final myAttendance = m['myAttendance'] as String?;
          final canRate      = !upcoming && !isCreator &&
                               myAttendance == 'attended' && !isRated;
          return _MatchCard(
            match: m,
            formatDate: _formatDate,
            parseDate: _parseDate,
            upcoming: upcoming,
            onTap: upcoming
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MatchDetailPage(matchId: m['matchId'] as int),
                      ),
                    ).then((_) => _fetchMatches())
                : null,
            onEvaluate: (!upcoming && isCreator && !isEvaluated)
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluateMatchPage(
                          matchId: m['matchId'] as int,
                          fieldName: m['fieldName'] as String,
                        ),
                      ),
                    ).then((evaluated) {
                      if (evaluated == true) _fetchMatches();
                    })
                : null,
            onRateOrganizer: canRate
                ? () => _showRateOrganizerDialog(m['matchId'] as int)
                : null,
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String Function(DateTime) formatDate;
  final DateTime Function(Map<String, dynamic>) parseDate;
  final bool upcoming;
  final VoidCallback? onTap;
  final VoidCallback? onEvaluate;
  final VoidCallback? onRateOrganizer;

  const _MatchCard({
    required this.match,
    required this.formatDate,
    required this.parseDate,
    required this.upcoming,
    this.onTap,
    this.onEvaluate,
    this.onRateOrganizer,
  });

  Color _skillColor(String level) {
    switch (level) {
      case 'Başlangıç':    return const Color(0xFF3A7A9A);
      case 'İleri Seviye': return const Color(0xFF2E5A1C);
      default:             return const Color(0xFF7A8A30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt          = parseDate(match);
    final fieldName   = match['fieldName'] as String;
    final city        = match['city'] as String? ?? '';
    final district    = match['district'] as String? ?? '';
    final level       = match['skillLevel'] as String;
    final current     = match['filledPlayers'] as int;
    final total       = match['requiredPlayers'] as int;
    final isCreator   = match['isCreator'] as bool? ?? false;
    final myPosition  = match['myPosition'] as String?;
    final status      = match['status'] as String? ?? 'active';
    final isFull      = status == 'full';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: upcoming ? Colors.white : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: upcoming
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fieldName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: upcoming
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF6A6A6A),
                    ),
                  ),
                ),
                _RoleBadge(isCreator: isCreator),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(dt),
              style: TextStyle(
                fontSize: 13,
                color: upcoming
                    ? const Color(0xFF7A7A7A)
                    : const Color(0xFF9A9A9A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$district, $city',
              style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.group,
                    size: 16,
                    color: upcoming
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFF9A9A9A)),
                const SizedBox(width: 5),
                Text(
                  '$current/$total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: upcoming
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF8A8A8A),
                  ),
                ),
                if (myPosition != null) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.sports_soccer,
                      size: 14,
                      color: upcoming
                          ? const Color(0xFF4A7A4A)
                          : const Color(0xFFAAAAAA)),
                  const SizedBox(width: 4),
                  Text(
                    myPosition,
                    style: TextStyle(
                      fontSize: 12,
                      color: upcoming
                          ? const Color(0xFF4A7A4A)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
                const Spacer(),
                if (isFull)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAAAAAA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('DOLU',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _skillColor(level),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
            if (onEvaluate != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEvaluate,
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('Maçı Değerlendir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A7A4A),
                    side: const BorderSide(color: Color(0xFF4A7A4A)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            if (onRateOrganizer != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRateOrganizer,
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text('Organizatörü Değerlendir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3A6A9A),
                    side: const BorderSide(color: Color(0xFF3A6A9A)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isCreator;

  const _RoleBadge({required this.isCreator});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCreator
            ? const Color(0xFF4A7A4A).withValues(alpha: 0.12)
            : const Color(0xFF3A6A9A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCreator ? 'Organizatör' : 'Katılımcı',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isCreator ? const Color(0xFF3A6A3A) : const Color(0xFF2A5A8A),
        ),
      ),
    );
  }
}
