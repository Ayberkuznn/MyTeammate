import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_page.dart';
import 'create_match_page.dart';
import 'match_detail_page.dart';
import 'login_page.dart';
import '../widgets/app_navbar.dart';
import '../services/auth_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          // 0 — Ana Sayfa
          _HomePage(onProfileTap: () => setState(() => _navIndex = 4)),
          // 1 — Arama
          const Center(child: Text('Arama')),
          // 2 — Maç Oluştur
          CreateMatchPage(
            onMatchCreated: () => setState(() => _navIndex = 0),
          ),
          // 3 — Bildirimler
          const Center(child: Text('Bildirimler')),
          // 4 — Profil
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─── Ana Sayfa ────────────────────────────────────────────────────────────────

class _HomePage extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const _HomePage({this.onProfileTap});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _viewIndex = 1; // 0: Harita, 1: Liste

  List<Map<String, dynamic>> _cityData = [];
  String? _selectedCity;
  String? _selectedDistrict;

  List<Map<String, dynamic>> _matches = [];
  bool _matchesLoading = false;
  String? _matchesError;

  List<String> get _cities =>
      _cityData.map((e) => e['city'] as String).toList();

  List<String> get _districts {
    if (_selectedCity == null) return [];
    final entry = _cityData.firstWhere(
      (e) => e['city'] == _selectedCity,
      orElse: () => {},
    );
    return List<String>.from(entry['counties'] as List? ?? []);
  }

  @override
  void initState() {
    super.initState();
    _loadCityData();
    _loadDefaultCityAndFetch();
  }

  Future<void> _loadCityData() async {
    final raw = await rootBundle.loadString('lib/data/city.json');
    final list = jsonDecode(raw) as List;
    if (mounted) setState(() => _cityData = list.cast<Map<String, dynamic>>());
  }

  Future<void> _loadDefaultCityAndFetch() async {
    final profile = await AuthService.getProfile();
    if (mounted && profile != null) {
      final city = profile['city'] as String?;
      if (city != null && city.isNotEmpty) {
        setState(() => _selectedCity = city);
      }
    }
    await _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    if (mounted) setState(() { _matchesLoading = true; _matchesError = null; });
    final result = await AuthService.getMatches(
      city: _selectedCity,
      district: _selectedDistrict,
    );
    if (!mounted) return;
    if (result.error != null && result.error!.startsWith('[401]')) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
      return;
    }
    setState(() {
      _matches = result.matches;
      _matchesError = result.error;
      _matchesLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month]} - $h:$m';
  }

  DateTime _parseMatchDate(Map<String, dynamic> match) {
    final dateStr = match['date'].toString().substring(0, 10);
    final timeStr = match['time'].toString().substring(0, 5);
    final d = dateStr.split('-');
    final t = timeStr.split(':');
    return DateTime(
      int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
      int.parse(t[0]), int.parse(t[1]),
    );
  }

  Color _skillColor(String level) {
    switch (level) {
      case 'Başlangıç':    return const Color(0xFF3A7A9A);
      case 'İleri Seviye': return const Color(0xFF2E5A1C);
      default:             return const Color(0xFF7A8A30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildFilterRow(),
            const SizedBox(height: 12),
            Expanded(
              child: _viewIndex == 1 ? _buildList() : _buildMapPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          _buildToggle(),
          const Spacer(),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFAAAAAA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A5A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_toggleTab('HARİTA', 0), _toggleTab('LİSTE', 1)],
      ),
    );
  }

  Widget _toggleTab(String label, int index) {
    final active = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6AAA3A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFFB8D8A0),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Yaklaşan Maçlar',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3A7A3A),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _filterDropdown(
              hint: 'İl',
              value: _selectedCity,
              items: _cities,
              onChanged: (v) {
                setState(() {
                  _selectedCity = v;
                  _selectedDistrict = null;
                });
                _fetchMatches();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _filterDropdown(
              hint: 'İlçe',
              value: _selectedDistrict,
              items: _districts,
              enabled: _selectedCity != null,
              onChanged: (v) {
                setState(() => _selectedDistrict = v);
                _fetchMatches();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: enabled ? const Color(0xFF9A9A9A) : const Color(0xFFBBBBBB),
              fontSize: 13,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: enabled ? const Color(0xFF4A4A4A) : const Color(0xFFBBBBBB),
            size: 20,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
          items: enabled
              ? items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList()
              : null,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_matchesLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A7A4A)));
    }

    if (_matchesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _matchesError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMatches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7A4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Center(
        child: Text(
          'Uygun maç bulunamadı.',
          style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMatchCard(_matches[i], highlighted: i == 0),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, {bool highlighted = false}) {
    final date = _parseMatchDate(match);
    final current = match['filledPlayers'] as int;
    final total = match['requiredPlayers'] as int;
    final level = match['skillLevel'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: const Color(0xFF4A7A4A), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match['fieldName'] as String,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 13, color: Color(0xFF7A7A7A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.group, size: 18, color: Color(0xFF3A3A3A)),
              const SizedBox(width: 6),
              Text(
                '$current/$total Oyuncu',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _skillColor(level),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: current < total
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchDetailPage(match: match),
                        ),
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7A4A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFAAAAAA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                current >= total ? 'DOLU' : 'KATIL',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Color(0xFFAAAAAA)),
          SizedBox(height: 12),
          Text(
            'Harita görünümü yakında',
            style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
          ),
        ],
      ),
    );
  }
}
