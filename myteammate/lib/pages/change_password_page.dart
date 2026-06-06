import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _currentObscure = true;
  bool _newObscure     = true;
  bool _confirmObscure = true;
  bool _loading        = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await AuthService.changePassword(
      _currentCtrl.text,
      _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre başarıyla değiştirildi.'),
          backgroundColor: Color(0xFF4A7A4A),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Bir hata oluştu.'),
          backgroundColor: const Color(0xFFAA3A3A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5A1C),
        foregroundColor: Colors.white,
        title: const Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _PasswordField(
                controller: _currentCtrl,
                label: 'Mevcut Şifre',
                obscure: _currentObscure,
                onToggle: () => setState(() => _currentObscure = !_currentObscure),
                validator: (v) => (v == null || v.isEmpty) ? 'Mevcut şifrenizi girin.' : null,
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _newCtrl,
                label: 'Yeni Şifre',
                obscure: _newObscure,
                onToggle: () => setState(() => _newObscure = !_newObscure),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Yeni şifrenizi girin.';
                  final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
                  if (!regex.hasMatch(v)) {
                    return 'En az 8 karakter, büyük/küçük harf ve rakam içermelidir.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Yeni Şifre (Tekrar)',
                obscure: _confirmObscure,
                onToggle: () => setState(() => _confirmObscure = !_confirmObscure),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Şifreyi tekrar girin.';
                  if (v != _newCtrl.text) return 'Şifreler eşleşmiyor.';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7A4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Şifreyi Değiştir',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4A7A4A), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFAA3A3A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFAA3A3A), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF8A8A8A),
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
