import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const double _bannerHeight = 200;
  static const double _avatarRadius = 44;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                _buildBanner(),
                _buildBody(),
              ],
            ),
            // Avatar — saha ile kart sınırını ortalar
            Positioned(
              top: _bannerHeight - _avatarRadius,
              left: 0,
              right: 0,
              child: const Center(child: _Avatar()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return SizedBox(
      height: _bannerHeight,
      width: double.infinity,
      child: Image.network(
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF2E5A1C),
          child: const Icon(Icons.sports_soccer, size: 64, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Avatar için boşluk
          const SizedBox(height: _avatarRadius + 16),

          // İsim
          const Text(
            'Arda Güler',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 20),

          // Mevki + Seviye
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(label: 'Orta Saha', color: Color(0xFF4A7A4A)),
              SizedBox(width: 12),
              _Badge(label: 'Orta Seviye', color: Color(0xFF7A7A2A)),
            ],
          ),

          const SizedBox(height: 12),

          // Kullanılan ayak
          const _Badge(label: '🦶 Sağ Ayak', color: Color(0xFF3A5A8A)),

          const SizedBox(height: 24),

          // Maç & Puan
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: _StatsCard(),
          ),

          const SizedBox(height: 16),

          // Ceza puanı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: _PenaltyCard(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFB0B0B0),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.person, size: 52, color: Color(0xFF555555)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D1E),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(value: '28', label: 'Maç'),
            VerticalDivider(color: Colors.white24, thickness: 1, width: 1),
            _StatItem(value: '4.6', label: 'Ort. Puan'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  const _PenaltyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD4A017), size: 22),
              SizedBox(width: 10),
              Text(
                'Toplam Ceza Puanı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6C8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '5',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB07000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
