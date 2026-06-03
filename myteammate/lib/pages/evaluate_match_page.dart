import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EvaluateMatchPage extends StatefulWidget {
  final int matchId;
  final String fieldName;

  const EvaluateMatchPage({
    super.key,
    required this.matchId,
    required this.fieldName,
  });

  @override
  State<EvaluateMatchPage> createState() => _EvaluateMatchPageState();
}

class _EvaluateMatchPageState extends State<EvaluateMatchPage> {
  List<Map<String, dynamic>> _participants = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  // userId -> {attended: bool, rating: int}
  final Map<int, _Eval> _evals = {};

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final data = await AuthService.getMatchParticipants(widget.matchId);
    if (!mounted) return;
    if (data == null) {
      setState(() { _loading = false; _error = 'Katılımcılar yüklenemedi.'; });
      return;
    }
    final evals = <int, _Eval>{};
    for (final p in data) {
      evals[p['userId'] as int] = _Eval(attended: true, rating: 4);
    }
    setState(() {
      _participants = data;
      _evals.addAll(evals);
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_evals.isEmpty) return;
    setState(() => _submitting = true);

    final evaluations = _evals.entries.map((e) => {
      'userId': e.key,
      'attended': e.value.attended,
      'rating': e.value.rating,
    }).toList();

    final result = await AuthService.evaluateMatch(widget.matchId, evaluations);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Değerlendirme kaydedildi!'),
          backgroundColor: const Color(0xFF4A8A3A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Bir hata oluştu.'),
          backgroundColor: const Color(0xFFAA3A3A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7A4A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maçı Değerlendir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(widget.fieldName,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A7A4A)))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFF8A8A8A))))
              : _participants.isEmpty
                  ? const Center(
                      child: Text('Bu maça katılan oyuncu bulunamadı.',
                          style: TextStyle(color: Color(0xFF8A8A8A))))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _participants.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _ParticipantCard(
                              participant: _participants[i],
                              eval: _evals[_participants[i]['userId'] as int]!,
                              onChanged: (eval) => setState(() =>
                                  _evals[_participants[i]['userId'] as int] =
                                      eval),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A7A4A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : const Text('Değerlendirmeyi Kaydet',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _Eval {
  final bool attended;
  final int rating;

  const _Eval({required this.attended, required this.rating});

  _Eval copyWith({bool? attended, int? rating}) =>
      _Eval(attended: attended ?? this.attended, rating: rating ?? this.rating);
}

class _ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;
  final _Eval eval;
  final ValueChanged<_Eval> onChanged;

  const _ParticipantCard({
    required this.participant,
    required this.eval,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name     = participant['name'] as String;
    final position = participant['position'] as String? ?? '';
    final rating   = (participant['avgRating'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFBBBBBB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(position,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A8A8A))),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFFE0A820)),
                  const SizedBox(width: 3),
                  Text(rating > 0 ? rating.toStringAsFixed(1) : '—',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Katıldı / Gelmedi toggle
          Row(
            children: [
              _AttendToggle(
                label: 'Katıldı',
                icon: Icons.check_circle_outline,
                selected: eval.attended,
                color: const Color(0xFF4A8A3A),
                onTap: () => onChanged(eval.copyWith(attended: true)),
              ),
              const SizedBox(width: 10),
              _AttendToggle(
                label: 'Gelmedi',
                icon: Icons.cancel_outlined,
                selected: !eval.attended,
                color: const Color(0xFFAA3A3A),
                onTap: () => onChanged(eval.copyWith(attended: false)),
              ),
            ],
          ),
          if (eval.attended) ...[
            const SizedBox(height: 14),
            const Text('Puan Ver',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A5A5A))),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => onChanged(eval.copyWith(rating: star)),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      star <= eval.rating ? Icons.star : Icons.star_border,
                      color: star <= eval.rating
                          ? const Color(0xFFE0A820)
                          : const Color(0xFFCCCCCC),
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
          ],
          if (!eval.attended)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: Color(0xFFAA3A3A)),
                  SizedBox(width: 6),
                  Text('10 ceza puanı uygulanacak',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFAA3A3A))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AttendToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? color : const Color(0xFFAAAAAA)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : const Color(0xFFAAAAAA))),
            ],
          ),
        ),
      ),
    );
  }
}
