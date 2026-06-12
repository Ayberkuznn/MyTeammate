import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // 0: e-posta, 1: kod, 2: yeni şifre
  int _step = 0;

  final _emailCtrl   = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _newObscure     = true;
  bool _confirmObscure = true;
  bool _loading        = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) => setState(() => _error = msg);

  // ── Adım 1: e-posta gönder ────────────────────────────────────────────────
  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _setError('E-posta adresinizi girin.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      setState(() => _step = 1);
    } else {
      _setError(result.error);
    }
  }

  // ── Adım 2: kodu doğrula ─────────────────────────────────────────────────
  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _setError('6 haneli kodu eksiksiz girin.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.verifyResetCode(_emailCtrl.text.trim(), code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      setState(() => _step = 2);
    } else {
      _setError(result.error);
    }
  }

  // ── Adım 3: şifreyi sıfırla ───────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final newPass     = _newCtrl.text;
    final confirmPass = _confirmCtrl.text;

    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!regex.hasMatch(newPass)) {
      _setError('Şifre en az 8 karakter, büyük/küçük harf ve rakam içermelidir.');
      return;
    }
    if (newPass != confirmPass) {
      _setError('Şifreler eşleşmiyor.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final result = await AuthService.resetPassword(
      _emailCtrl.text.trim(),
      _codeCtrl.text.trim(),
      newPass,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz başarıyla sıfırlandı. Giriş yapabilirsiniz.'),
          backgroundColor: Color(0xFF4A7A4A),
        ),
      );
      Navigator.pop(context);
    } else {
      // Kod hatalıysa 2. adıma döndür
      setState(() { _step = 1; _error = result.error; });
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    if (_step == 0) {
                      Navigator.pop(context);
                    } else {
                      setState(() { _step--; _error = null; });
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '⚽',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _stepTitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stepSubtitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      if (_step == 0) _buildEmailStep(),
                      if (_step == 1) _buildCodeStep(),
                      if (_step == 2) _buildPasswordStep(),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAA3A3A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E2E2E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _step == 2 ? 'Şifreyi Kaydet' : 'Devam Et',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
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

  String _stepTitle() {
    switch (_step) {
      case 0: return 'Şifremi Unuttum';
      case 1: return 'Kodu Girin';
      default: return 'Yeni Şifre';
    }
  }

  String _stepSubtitle() {
    switch (_step) {
      case 0: return 'Kayıtlı e-posta adresinizi girin.';
      case 1: return 'E-postanıza gönderilen 6 haneli kodu girin.';
      default: return 'Yeni şifrenizi belirleyin.';
    }
  }

  void _onNext() {
    switch (_step) {
      case 0: _sendCode();     break;
      case 1: _verifyCode();   break;
      case 2: _resetPassword(); break;
    }
  }

  Widget _buildEmailStep() {
    return _field(
      controller: _emailCtrl,
      hint: 'Mail Adresi',
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildCodeStep() {
    return _field(
      controller: _codeCtrl,
      hint: '6 Haneli Kod',
      keyboardType: TextInputType.number,
      maxLength: 6,
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        _field(
          controller: _newCtrl,
          hint: 'Yeni Şifre',
          obscure: _newObscure,
          suffixIcon: IconButton(
            icon: Icon(
              _newObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () => setState(() => _newObscure = !_newObscure),
          ),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _confirmCtrl,
          hint: 'Yeni Şifre (Tekrar)',
          obscure: _confirmObscure,
          suffixIcon: IconButton(
            icon: Icon(
              _confirmObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () => setState(() => _confirmObscure = !_confirmObscure),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB8C9B0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLength: maxLength,
        style: const TextStyle(color: Color(0xFF2A2A2A), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 14),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
