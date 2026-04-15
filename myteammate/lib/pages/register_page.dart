import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  DateTime? _selectedDate;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedPosition;
  String? _selectedFoot;

  final List<String> _positions = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];

  final List<String> _feet = ['Sağ', 'Sol', 'Her İkisi'];

  final List<String> _cities = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce',
  ];

  final List<String> _districts = [
    'Kadıköy',
    'Beşiktaş',
    'Üsküdar',
    'Fatih',
    'Beyoğlu',
    'Şişli',
    'Bağcılar',
    'Bahçelievler',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A8A5A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // Geri butonu
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

              // Başlık
              const Text(
                'Takım Arkadaşım',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Futbol topu
              const Text('⚽', style: TextStyle(fontSize: 56)),

              const SizedBox(height: 16),

              // Form alanları
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Ad
                      _buildTextField(controller: _nameController, hint: 'Ad'),
                      const SizedBox(height: 10),

                      // Soyad
                      _buildTextField(
                        controller: _surnameController,
                        hint: 'Soyad',
                      ),
                      const SizedBox(height: 10),

                      // Doğum Günü
                      _buildDateField(),
                      const SizedBox(height: 10),

                      // İl + İlçe yan yana
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildDropdown(
                              hint: 'İl',
                              value: _selectedCity,
                              items: _cities,
                              onChanged: (val) =>
                                  setState(() => _selectedCity = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6,
                            child: _buildDropdown(
                              hint: 'İlçe',
                              value: _selectedDistrict,
                              items: _districts,
                              onChanged: (val) =>
                                  setState(() => _selectedDistrict = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Mail
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Mail',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      // Telefon Numarası
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Telefon Numarası',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),

                      // Şifre
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Şifre',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tekrar Şifre
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Tekrar Şifre',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tercih Edilen Pozisyon
                      _buildDropdown(
                        hint: 'Tercih Edilen Pozisyon',
                        value: _selectedPosition,
                        items: _positions,
                        onChanged: (val) =>
                            setState(() => _selectedPosition = val),
                      ),
                      const SizedBox(height: 10),

                      // Kullanılan Ayak
                      _buildDropdown(
                        hint: 'Kullanılan Ayak',
                        value: _selectedFoot,
                        items: _feet,
                        onChanged: (val) => setState(() => _selectedFoot = val),
                      ),
                      const SizedBox(height: 16),

                      // Kayıt Ol butonu
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {},
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
                          child: const Text(
                            'Kayıt Ol',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB8C9B0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Color(0xFF2A2A2A), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB8C9B0),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                  : 'Doğum Günü',
              style: TextStyle(
                color: _selectedDate != null
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFF4A4A4A),
                fontSize: 14,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF4A4A4A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB8C9B0),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF4A4A4A),
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
