import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    final data = await AuthService.getMatchRequests();
    if (!mounted) return;
    if (data == null) {
      setState(() { _loading = false; _error = 'İstekler yüklenemedi.'; });
    } else {
      setState(() { _loading = false; _requests = data; });
    }
  }

  List<Map<String, dynamic>> get _pending =>
      _requests.where((r) => r['status'] == 0).toList();

  List<Map<String, dynamic>> get _resolved =>
      _requests.where((r) => r['status'] != 0).toList();

  Future<void> _accept(int requestId) async {
    final result = await AuthService.acceptRequest(requestId);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        final idx = _requests.indexWhere((r) => r['requestId'] == requestId);
        if (idx != -1) _requests[idx] = {..._requests[idx], 'status': 1};
      });
      _showSnack('Katılım isteği kabul edildi.', const Color(0xFF4A8A3A));
    } else {
      _showSnack(result.error ?? 'Bir hata oluştu.', const Color(0xFFAA3A3A));
    }
  }

  Future<void> _reject(int requestId) async {
    final result = await AuthService.rejectRequest(requestId);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        final idx = _requests.indexWhere((r) => r['requestId'] == requestId);
        if (idx != -1) _requests[idx] = {..._requests[idx], 'status': 2};
      });
      _showSnack('Katılım isteği reddedildi.', const Color(0xFFAA3A3A));
    } else {
      _showSnack(result.error ?? 'Bir hata oluştu.', const Color(0xFFAA3A3A));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'Bildirimler',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3A7A3A),
            ),
          ),
          const Spacer(),
          if (_pending.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A8A3A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_pending.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_pending.isNotEmpty) const SizedBox(width: 8),
          IconButton(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh, color: Color(0xFF4A7A4A)),
            tooltip: 'Yenile',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
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
          tabs: [
            Tab(text: 'BEKLEYEN (${_pending.length})'),
            Tab(text: 'GEÇMİŞ (${_resolved.length})'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A7A4A)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRequests,
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
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(_pending, showActions: true),
        _buildList(_resolved, showActions: false),
      ],
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required bool showActions,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showActions
                  ? Icons.notifications_none_outlined
                  : Icons.history_outlined,
              size: 56,
              color: const Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 12),
            Text(
              showActions ? 'Bekleyen istek yok.' : 'Henüz işlem yapılmadı.',
              style: const TextStyle(fontSize: 15, color: Color(0xFF9A9A9A)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _RequestCard(
        data: items[i],
        showActions: showActions,
        onAccept: () => _accept(items[i]['requestId'] as int),
        onReject: () => _reject(items[i]['requestId'] as int),
      ),
    );
  }
}

// ─── Kart ─────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showActions;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.data,
    required this.showActions,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name      = data['userName'] as String;
    final rating    = (data['userRating'] as num).toDouble();
    final fieldName = data['fieldName'] as String;
    final date      = data['matchDate'] as String;
    final time      = data['matchTime'] as String;
    final status    = data['status'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFF5A5A5A)),
                        const SizedBox(width: 3),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '—',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5A5A5A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!showActions) _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer,
                    size: 16, color: Color(0xFF5A5A5A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fieldName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2A2A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today,
                    size: 14, color: Color(0xFF7A7A7A)),
                const SizedBox(width: 4),
                Text(
                  '$date  $time',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
                ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reddet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFAA3A3A),
                      side: const BorderSide(color: Color(0xFFAA3A3A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Kabul Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A8A3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccepted
            ? const Color(0xFFDFF0D8)
            : const Color(0xFFF8D7D7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAccepted ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: isAccepted ? const Color(0xFF3A7A3A) : const Color(0xFFAA3A3A),
          ),
          const SizedBox(width: 4),
          Text(
            isAccepted ? 'Kabul' : 'Red',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isAccepted ? const Color(0xFF3A7A3A) : const Color(0xFFAA3A3A),
            ),
          ),
        ],
      ),
    );
  }
}
