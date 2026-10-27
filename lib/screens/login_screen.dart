import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../widgets/custom_widgets.dart';
import '../providers/theme_provider.dart';
import '../providers/firebase_auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );

    bool success;
    if (isLogin) {
      success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        _showSnackBar('🎉 Hoş geldin! Giriş başarılı.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        _showSnackBar(
          authProvider.errorMessage ??
              'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.',
          isError: true,
        );
      }
    } else {
      success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        displayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
      );

      if (success && mounted) {
        _showSnackBar('✨ Hesabın oluşturuldu! Hoş geldin.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        _showSnackBar(
          authProvider.errorMessage ??
              'Kayıt başarısız. Lütfen tekrar deneyin.',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<FirebaseAuthProvider>(
      context,
      listen: false,
    );

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      _showSnackBar('🎉 Google ile giriş başarılı!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      _showSnackBar(
        authProvider.errorMessage ?? 'Google girişi başarısız.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<FirebaseAuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, size: 22),
            tooltip: 'Tema',
            onPressed: () => Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header - Minimal
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.language,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing12),
                    Text(
                      AppConstants.appName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing4),
                    Text(
                      'Teknik Terimleri Öğren',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form - Minimal padding
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Login/Register Toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isLogin = true;
                                _nameController.clear();
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  'Giriş Yap',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isLogin
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacing8),
                                Container(
                                  height: 2,
                                  color: isLogin
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing32),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isLogin = false;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  'Kayıt Ol',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: !isLogin
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacing8),
                                Container(
                                  height: 2,
                                  color: !isLogin
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacing32),

                    // Name Field (Register only)
                    if (!isLogin)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.spacing16,
                        ),
                        child: CustomTextField(
                          label: 'Adınız',
                          hint: 'Adınızı girin',
                          controller: _nameController,
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (!isLogin && (value?.isEmpty ?? true)) {
                              return 'Adınızı girin';
                            }
                            return null;
                          },
                        ),
                      ),

                    // Email Field
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.spacing16,
                      ),
                      child: CustomTextField(
                        label: 'E-posta Adresi',
                        hint: 'ornek@email.com',
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'E-posta adresi gerekli';
                          }
                          if (!value!.contains('@')) {
                            return 'Geçerli bir e-posta girin';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Password Field
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.spacing24,
                      ),
                      child: CustomTextField(
                        label: 'Şifre',
                        hint: '••••••••',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outlined,
                        obscureText: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Şifre gerekli';
                          }
                          if (value!.length < 6) {
                            return 'Şifre en az 6 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Forgot Password (Login only)
                    if (isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _showSnackBar('Şifre sıfırlama yakında eklenecek!');
                          },
                          child: Text(
                            'Şifremi Unuttum',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Login Button
                    GradientButton(
                      label: isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleEmailAuth,
                      isLoading: authProvider.isLoading,
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing16,
                          ),
                          child: Text(
                            'veya',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Social Login Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              'Google ile Giriş',
                              'lib/assets/google_logo.svg',
                              background: Colors.white,
                              textColor: Colors.black87,
                              shadow: true,
                              onTap: authProvider.isLoading
                                  ? null
                                  : _handleGoogleSignIn,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildSocialButton(
                              'Apple ile Giriş',
                              'lib/assets/apple_logo.svg',
                              background: Colors.black,
                              textColor: Colors.white,
                              shadow: true,
                              onTap: authProvider.isLoading
                                  ? null
                                  : () {
                                      _showSnackBar(
                                        'Apple Sign-In yakında eklenecek!',
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String label,
    String assetName, {
    Color background = Colors.white,
    Color textColor = Colors.black87,
    bool shadow = false,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(assetName, width: 26, height: 26),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
