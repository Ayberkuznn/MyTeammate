import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditProfilePage({super.key, required this.currentProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedPosition;
  String? _selectedFoot;
  String? _selectedSkillLevel;
  bool _isLoading = false;

  final List<String> _positions   = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];
  final List<String> _feet        = ['Sağ', 'Sol', 'Her İkisi'];
  final List<String> _skillLevels = ['Başlangıç', 'Orta Seviye', 'İleri Seviye'];

  List<Map<String, dynamic>> _cityData = [];

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

  Future<void> _loadCityData() async {
    final raw = await rootBundle.loadString('lib/data/city.json');
    final list = jsonDecode(raw) as List;
    if (mounted) {
      setState(() {
        _cityData = list.cast<Map<String, dynamic>>();
        final p = widget.currentProfile;
        _selectedCity     = _cities.contains(p['city'])     ? p['city']     : _selectedCity;
        _selectedDistrict = _districts.contains(p['district']) ? p['district'] : null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _selectedPosition   = _positions.contains(p['position'])   ? p['position']   : null;
    _selectedFoot       = _feet.contains(p['foot'])            ? p['foot']       : null;
    _selectedSkillLevel = _skillLevels.contains(p['skillLevel']) ? p['skillLevel'] : null;
    _loadCityData();
  }

  bool get _isFormValid =>
      _selectedCity != null &&
      _selectedDistrict != null &&
      _selectedPosition != null &&
      _selectedFoot != null &&
      _selectedSkillLevel != null;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.updateProfile({
        'City': _selectedCity,
        'District': _selectedDistrict,
        'Position': _selectedPosition,
        'Foot': _selectedFoot,
        'Skill_level': _selectedSkillLevel,
      });

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Bir hata oluştu.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sunucuya bağlanılamadı.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.currentProfile;
    final name = '${p['name']} ${p['surname']}';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A8A5A), Color(0xFF7AAD6E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF2A2A2A),
                    size: 22,
                  ),
                ),
              ),
              const Text(
                'Profili Düzenle',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Değişmeyen alanlar (salt okunur)
                      _buildSectionLabel('Kişisel Bilgiler'),
                      const SizedBox(height: 8),
                      _buildReadOnlyField(
                        label: 'Ad Soyad',
                        value: name.toUpperCase(),
                      ),
                      const SizedBox(height: 24),

                      // Düzenlenebilir alanlar
                      _buildSectionLabel('Konum'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildDropdown(
                              hint: 'İl',
                              value: _selectedCity,
                              items: _cities,
                              onChanged: (val) => setState(() {
                                _selectedCity = val;
                                _selectedDistrict = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6,
                            child: _buildDropdown(
                              hint: 'İlçe',
                              value: _selectedDistrict,
                              items: _districts,
                              enabled: _selectedCity != null,
                              onChanged: (val) =>
                                  setState(() => _selectedDistrict = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionLabel('Futbol Bilgileri'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        hint: 'Tercih Edilen Pozisyon',
                        value: _selectedPosition,
                        items: _positions,
                        onChanged: (val) =>
                            setState(() => _selectedPosition = val),
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        hint: 'Kullanılan Ayak',
                        value: _selectedFoot,
                        items: _feet,
                        onChanged: (val) => setState(() => _selectedFoot = val),
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        hint: 'Yetenek Seviyesi',
                        value: _selectedSkillLevel,
                        items: _skillLevels,
                        onChanged: (val) =>
                            setState(() => _selectedSkillLevel = val),
                      ),
                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isLoading || !_isFormValid ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E2E2E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kaydet',
                                  style: TextStyle(fontSize: 14),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2A2A2A),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF9DB89D),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(color: Color(0xFF2A2A2A), fontSize: 14),
          ),
          const Icon(Icons.lock_outline, size: 16, color: Color(0xFF5A5A5A)),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFB8C9B0) : const Color(0xFFD0D0D0),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: enabled ? const Color(0xFF4A4A4A) : const Color(0xFFAAAAAA),
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: enabled ? const Color(0xFF4A4A4A) : const Color(0xFFAAAAAA),
            size: 20,
          ),
          dropdownColor: const Color(0xFFB8C9B0),
          style: const TextStyle(color: Color(0xFF2A2A2A), fontSize: 14),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
