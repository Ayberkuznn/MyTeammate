import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class CreateMatchPage extends StatefulWidget {
  const CreateMatchPage({super.key});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  // il → ilçeler haritası (JSON'dan yüklenir)
  List<Map<String, dynamic>> _cityData = [];

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedField;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  int _kaleci = 1;
  int _defans = 0;
  int _ortaSaha = 0;
  int _forvet = 0;

  int _skillIndex = 1;

  final _feeController = TextEditingController();

  List<Map<String, dynamic>> _fieldData = [];
  bool _fieldsLoading = false;

  List<String> get _fieldNames =>
      _fieldData.map((e) => e['name'] as String).toList();

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
  }

  Future<void> _loadCityData() async {
    final raw = await rootBundle.loadString('lib/data/city.json');
    final list = jsonDecode(raw) as List;
    if (mounted) {
      setState(() {
        _cityData = list.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _loadFields() async {
    if (_selectedCity == null || _selectedDistrict == null) return;
    setState(() {
      _fieldsLoading = true;
      _fieldData = [];
      _selectedField = null;
    });
    final data = await AuthService.getFields(
      city: _selectedCity!,
      district: _selectedDistrict!,
    );
    if (mounted)
      setState(() {
        _fieldData = data;
        _fieldsLoading = false;
      });
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'OCA',
      'ŞUB',
      'MAR',
      'NİS',
      'MAY',
      'HAZ',
      'TEM',
      'AĞU',
      'EYL',
      'EKİ',
      'KAS',
      'ARA',
    ];
    return '${d.day} ${months[d.month]}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4A7A4A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4A7A4A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  int get _totalMissing => _kaleci + _defans + _ortaSaha + _forvet;

  bool get _isFormValid =>
      _selectedCity != null &&
      _selectedDistrict != null &&
      _selectedField != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Saha Seçiniz'),
                    const SizedBox(height: 10),
                    _buildLocationRow(),
                    const SizedBox(height: 10),
                    _buildFieldRow(),
                    const SizedBox(height: 22),
                    _sectionLabel('Tarih & Saat'),
                    const SizedBox(height: 10),
                    _buildDateTimeRow(),
                    const SizedBox(height: 22),
                    _sectionLabel('Eksik Oyuncular'),
                    const SizedBox(height: 10),
                    _buildMissingPlayersCard(),
                    const SizedBox(height: 16),
                    _buildSkillTabs(),
                    const SizedBox(height: 22),
                    _sectionLabel('Kişi Başı Ücret'),
                    const SizedBox(height: 10),
                    _buildFeeField(),
                    const SizedBox(height: 28),
                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF2A2A2A),
            ),
            onPressed: () {},
          ),
          const Text(
            'Maç Oluştur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _dropdown(
            hint: 'İl',
            value: _selectedCity,
            items: _cities,
            onChanged: (v) {
              setState(() {
                _selectedCity = v;
                _selectedDistrict = null;
                _fieldData = [];
                _selectedField = null;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: _dropdown(
            hint: 'İlçe',
            value: _selectedDistrict,
            items: _districts,
            enabled: _selectedCity != null,
            onChanged: (v) {
              setState(() => _selectedDistrict = v);
              _loadFields();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldRow() {
    final fieldEnabled =
        _selectedCity != null && _selectedDistrict != null && !_fieldsLoading;
    final hint = _fieldsLoading
        ? 'Yükleniyor...'
        : (_fieldNames.isEmpty && _selectedDistrict != null
              ? 'Saha bulunamadı'
              : 'Saha');
    return Row(
      children: [
        Expanded(
          child: _dropdown(
            hint: hint,
            value: _selectedField,
            items: _fieldNames,
            enabled: fieldEnabled && _fieldNames.isNotEmpty,
            onChanged: (v) => setState(() => _selectedField = v),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF3A5A8A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: _pickerBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF4A4A4A),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: _pickerBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(_selectedTime),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF4A4A4A),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pickerBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMissingPlayersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A7A4A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _counterRow('Kaleci', _kaleci, (v) => setState(() => _kaleci = v)),
          _counterRow('Defans', _defans, (v) => setState(() => _defans = v)),
          _counterRow(
            'Orta Saha',
            _ortaSaha,
            (v) => setState(() => _ortaSaha = v),
          ),
          _counterRow('Forvet', _forvet, (v) => setState(() => _forvet = v)),
        ],
      ),
    );
  }

  Widget _counterRow(String label, int value, ValueChanged<int> onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          _counterBtn(
            icon: Icons.remove,
            onTap: value > 0 ? () => onChange(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          _counterBtn(icon: Icons.add, onTap: () => onChange(value + 1)),
        ],
      ),
    );
  }

  Widget _counterBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF4A7A4A) : const Color(0xFFCCCCCC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildSkillTabs() {
    const labels = ['Başlangıç', 'Orta', 'İleri'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD6E8D0),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = _skillIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _skillIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF4A7A4A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _feeController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: '0 ₺',
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
          suffixText: '₺',
          suffixStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A7A4A),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isFormValid ? _createMatch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E5A1C),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFAAAAAA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
        child: const Text(
          'Maç Oluştur',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    void Function(String?)? onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFF9A9A9A)
                  : const Color(0xFFBBBBBB),
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: enabled ? const Color(0xFF4A4A4A) : const Color(0xFFBBBBBB),
            size: 20,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
          items: enabled
              ? items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList()
              : null,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _createMatch() {
    const skillLevels = ['Başlangıç', 'Orta Seviye', 'İleri Seviye'];
    final fee = _feeController.text.isEmpty
        ? 0
        : int.parse(_feeController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Maç oluşturuldu! Saha: $_selectedField | '
          '${_formatDate(_selectedDate)} ${_formatTime(_selectedTime)} | '
          'Eksik: $_totalMissing | Seviye: ${skillLevels[_skillIndex]} | Ücret: $fee ₺',
        ),
        backgroundColor: const Color(0xFF4A7A4A),
      ),
    );
  }
}
