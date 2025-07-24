import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:country_picker/country_picker.dart';
import 'package:its19/screens/forgot_password_page.dart';
import 'package:its19/screens/home_page.dart';
import 'package:its19/screens/privacy_policy_page.dart';
import 'package:flutter/gestures.dart';
import 'package:its19/screens/terms_conditions_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

void main() {
  runApp(const Its19App());
}

class Its19App extends StatelessWidget {
  const Its19App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'its19',
      theme: ThemeData(
        primaryColor: const Color(0xFF059669),
        scaffoldBackgroundColor: const Color(0xFFF0FDFA),
        fontFamily: 'Cocon',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
        ),
      ),
      home: const Its19LoginPage(),
    );
  }
}

class Its19LoginPage extends StatefulWidget {
  const Its19LoginPage({super.key});

  @override
  _Its19LoginPageState createState() => _Its19LoginPageState();
}

class _Its19LoginPageState extends State<Its19LoginPage> {
  bool _showPassword = false;
  bool _isLogin = true;
  final _formData = {
    'name': '',
    'judgeName': '',
    'email': '',
    'password': '',
    'country': '',
    'activationCode': '',
    'oath': false,
  };
  final _errors = <String, String>{};

  void _handleInputChange(String field, dynamic value) {
    setState(() {
      _formData[field] = value;
      if (_errors.containsKey(field)) {
        _errors.remove(field);
      }
    });
  }

  bool _validateForm() {
    final newErrors = <String, String>{};

    if (!_isLogin) {
      final judgeName = _formData['judgeName'] as String;
      if (judgeName.isEmpty || judgeName.length < 8 || judgeName.length > 171) {
        newErrors['judgeName'] = 'Yargıç Adı en az 8 karakter olmalıdır.';
      }
      if (!(_formData['oath'] as bool)) {
        newErrors['oath'] = 'Lütfen önce yemin ediniz.';
      }
    }

    final email = _formData['email'] as String;
    if (email.isEmpty || !email.contains('@')) {
      newErrors['email'] = 'Geçerli bir e-posta adresi giriniz.';
    }

    final password = _formData['password'] as String;
    if (password.isEmpty || password.length < 8 || password.length > 19) {
      newErrors['password'] = 'Şifre en az 8 karakter olmalıdır.';
    }

    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });

    return newErrors.isEmpty;
  }

  void _handleSubmit() {
    if (_isLogin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt işlemi başarılı. Lütfen e-postanızı kontrol ediniz ve hesabınızı aktifleştirmek için gönderilen linke tıklayınız.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/icons/00_giris_gavel_ust_icon.png',
                              width: 60,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'its19',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hükmünü ver, adaleti sağla.',
                          style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Login/Register Toggle
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: _isLogin ? const Color(0xFF059669) : Colors.transparent,
                                foregroundColor: _isLogin ? Colors.white : Colors.grey[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => setState(() => _isLogin = true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'lib/icons/00_giris_mini_gavel.png',
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Giriş', style: TextStyle(fontWeight: FontWeight.w600)),//                            onPressed: _handleSubmit,//buton tıklandığında  lib/screens/home_page.dart bu sayfaya yönlendirme olacak
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: !_isLogin ? const Color(0xFF059669) : Colors.transparent,
                                foregroundColor: !_isLogin ? Colors.white : Colors.grey[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => setState(() => _isLogin = false),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FeatherIcons.userPlus, size: 16),
                                  SizedBox(width: 8),
                                  Text('Kaydol', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[

                          // Yargıç Adı
                          _buildTextField(
                            label: 'Yargıç Adı',
                            icon: FeatherIcons.anchor,
                            placeholder: 'Kullanıcı adınız (min 8 karakter)',
                            field: 'judgeName',
                            error: _errors['judgeName'],
                            onChanged: (value) => _handleInputChange('judgeName', value),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // E-Posta
                        _buildTextField(
                          label: 'E-Posta',
                          icon: FeatherIcons.mail,
                          placeholder: 'ornek@email.com',
                          field: 'email',
                          error: _errors['email'],
                          onChanged: (value) => _handleInputChange('email', value),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Şifre
                        _buildTextField(
                          label: 'Şifre',
                          icon: FeatherIcons.lock,
                          placeholder: '8-19 karakter arası',
                          field: 'password',
                          error: _errors['password'],
                          obscureText: !_showPassword,
                          onChanged: (value) => _handleInputChange('password', value),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? FeatherIcons.eyeOff : FeatherIcons.eye,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (!_isLogin) ...[
                          // Ülke Seçimi (country_picker ile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(FeatherIcons.globe, size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Ülkeniz',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: false,
                                    onSelect: (Country country) {
                                      _handleInputChange('country', country.name);
                                    },
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(minHeight: 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    (_formData['country'] as String?)?.isNotEmpty == true
                                      ? _formData['country'] as String
                                      : 'کوردستان', // Varsayılan olarak bu kelime seçili gelsin
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                              ),

                            ],
                          ),
                          // Yemin
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _formData['oath'] as bool,
                                onChanged: (value) => _handleInputChange('oath', value!),
                                activeColor: const Color(0xFF059669),
                              ),
                              Expanded(

                                child: Align(
                                  alignment: Alignment.centerLeft,heightFactor: 1.5,

                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      children: [
                                        const TextSpan(text: 'Adil bir yargıç olacağıma, '),
                                        TextSpan(
                                          text: 'gizlilik',
                                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.white,
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                builder: (context) => const PrivacyPolicyPage(),
                                              );
                                            },
                                        ),
                                        const TextSpan(text: ' ve '),
                                        TextSpan(
                                          text: 'koşullarınızı',
                                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.white,
                                              shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                              ),
                                              builder: (context) => const TermsConditionsPage(),
                                              );
                                            },
                                        ),
                                        const TextSpan(text: ' kabul ettiğime dair tüm mukaddesatım üzerine yemin ederim.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errors['oath'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(FeatherIcons.alertCircle, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    _errors['oath']!,
                                    style: const TextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'lib/icons/00_giris_mini_gavel.png',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Text(_isLogin ? 'GİRİŞ YAP' : 'KAYDET'),
                              ],
                            ),
                          ),
                        ),

                        // Forgot Password
                        if (_isLogin)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Şifreni mi unuttun?',
                                style: TextStyle(color: Color(0xFF059669)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Daily Case & Virtual Action
                  if (_isLogin) ...[
                    Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Günün Davası
                          Card(
                            color: const Color(0xFFF0F9FF),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {},
                                hoverColor: Colors.green.shade50, // Web/Masaüstü için
                                splashColor: Colors.green.withOpacity(0.2), // Mobil için tıklama efekti
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border(
                                      left: BorderSide(color: Color(0xFF059669), width: 4),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            MdiIcons.gavel, // Günün Davası için uygun icon
                                            size: 16,
                                            color: Colors.blue,

                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Günün Davası',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'İsrail, Filistin davasında sizce kim haklı ? ',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Haykıra Katıl
                          Card(
                            color: const Color(0xFFF0F9FF),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {},
                                hoverColor: Colors.green.shade50, // Web/Masaüstü için
                                splashColor: Colors.green.withOpacity(0.2), // Mobil için tıklama efekti
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border(
                                      left: BorderSide(color: Color(0xFF0D9488), width: 4),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'lib/icons/00_giris_haykira_katil_icon.png',
                                            width: 16,
                                            height: 16,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Haykıra Katıl',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Ses ver, tarafını seç!',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),
                  // Footer
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF059669),
                    child: const Text(
                      'Düşün; ölç ve  biç. Tanrının adaletine katıl',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String placeholder,
    required String field,
    String? error,
    bool obscureText = false,
    Function(String)? onChanged,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            errorText: error,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}