import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../models/user_preferences.dart';

class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Kullanıcı tercihlerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.isLoggedIn) {
        userProvider.loadUserPreferences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Ayarlar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: Consumer2<UserProvider, ThemeProvider>(
        builder: (context, userProvider, themeProvider, _) {
          final preferences = userProvider.userPreferences;
          final isLoading = userProvider.isLoading;

          if (isLoading && preferences == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing16,
              vertical: AppConstants.spacing12,
            ),
            children: [
              // Tema Ayarları
              _buildSectionTitle('🎨 Görünüm'),
              const SizedBox(height: AppConstants.spacing12),
              _buildThemeCard(themeProvider),

              const SizedBox(height: AppConstants.spacing24),

              // Bildirim Ayarları
              _buildSectionTitle('🔔 Bildirimler'),
              const SizedBox(height: AppConstants.spacing12),
              _buildNotificationSettings(userProvider, preferences),

              const SizedBox(height: AppConstants.spacing24),

              // İçerik Ayarları
              _buildSectionTitle('📚 İçerik'),
              const SizedBox(height: AppConstants.spacing12),
              _buildContentSettings(userProvider, preferences),

              const SizedBox(height: AppConstants.spacing24),

              // Hesap Ayarları
              _buildSectionTitle('👤 Hesap'),
              const SizedBox(height: AppConstants.spacing12),
              _buildAccountSettings(context, userProvider),

              const SizedBox(height: AppConstants.spacing32),

              // Veri Yönetimi
              _buildSectionTitle('💾 Veri Yönetimi'),
              const SizedBox(height: AppConstants.spacing12),
              _buildDataManagement(context, userProvider),

              const SizedBox(height: AppConstants.spacing32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _buildThemeCard(ThemeProvider themeProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.brightness_6, color: AppColors.primary),
            ),
            title: Text(
              'Tema Modu',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _getThemeModeName(themeProvider.themeMode),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModeDialog(themeProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(
    UserProvider userProvider,
    UserPreferences? preferences,
  ) {
    if (!userProvider.isLoggedIn) {
      return _buildLoginRequiredCard();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications, color: AppColors.primary),
            ),
            title: Text(
              'Bildirimler',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Bildirim almak istiyorum',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            value: preferences?.notificationsEnabled ?? true,
            onChanged: (value) {
              userProvider.updateNotificationSettings(enabled: value);
            },
          ),
          if (preferences?.notificationsEnabled ?? false) ...[
            const Divider(height: 1),
            SwitchListTile(
              secondary: const SizedBox(width: 40),
              title: Text('Ses', style: GoogleFonts.poppins(fontSize: 14)),
              value: preferences?.soundEnabled ?? true,
              onChanged: (value) {
                userProvider.updateNotificationSettings(sound: value);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const SizedBox(width: 40),
              title: Text('Titreşim', style: GoogleFonts.poppins(fontSize: 14)),
              value: preferences?.vibrationEnabled ?? true,
              onChanged: (value) {
                userProvider.updateNotificationSettings(vibration: value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSettings(
    UserProvider userProvider,
    UserPreferences? preferences,
  ) {
    if (!userProvider.isLoggedIn) {
      return _buildLoginRequiredCard();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.text_fields, color: AppColors.primary),
            ),
            title: Text(
              'Yazı Boyutu',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${preferences?.fontSize.toInt() ?? 16}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Slider(
              value: preferences?.fontSize ?? 16.0,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              label: '${preferences?.fontSize.toInt() ?? 16}',
              onChanged: (value) {
                userProvider.updatePreferences({'fontSize': value});
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.book, color: AppColors.primary),
            ),
            title: Text(
              'Günlük Kelime Sayısı',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${preferences?.wordsPerDay ?? 10} kelime',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(
    BuildContext context,
    UserProvider userProvider,
  ) {
    final authProvider = context.read<FirebaseAuthProvider>();
    final user = authProvider.currentUser;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          if (user != null) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(
                'Hesap Bilgileri',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                user.email ?? 'Email bulunamadı',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: Text(
              'Çıkış Yap',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context, UserProvider userProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download, color: AppColors.primary),
            ),
            title: Text(
              'Verileri Dışa Aktar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Tüm verilerinizi indirin',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: userProvider.isLoggedIn
                ? () => _exportUserData(context, userProvider)
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            title: Text(
              'Hesabı Sil',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              'Tüm verileriniz silinecek',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            onTap: userProvider.isLoggedIn
                ? () => _deleteAccount(context, userProvider)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Giriş Yapmanız Gerekiyor',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu özellikleri kullanmak için lütfen giriş yapın',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Giriş Yap',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem Ayarı';
    }
  }

  void _showThemeModeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tema Seçin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              'Açık Tema',
              Icons.light_mode,
              ThemeMode.light,
              themeProvider,
            ),
            _buildThemeOption(
              'Koyu Tema',
              Icons.dark_mode,
              ThemeMode.dark,
              themeProvider,
            ),
            _buildThemeOption(
              'Sistem Ayarı',
              Icons.settings_brightness,
              ThemeMode.system,
              themeProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Çıkış Yap',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Çıkış yapmak istediğinize emin misiniz?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Çıkış Yap',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<FirebaseAuthProvider>();
      final userProvider = context.read<UserProvider>();
      final themeProvider = context.read<ThemeProvider>();

      await authProvider.logout();
      userProvider.clearUserData();
      await themeProvider.onUserLogout();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _exportUserData(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final data = await userProvider.exportUserData();
    Navigator.pop(context); // Close loading

    if (data != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Veriler başarıyla dışa aktarıldı',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Veriler dışa aktarılamadı',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '⚠️ Dikkat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Hesabı Sil',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await userProvider.deleteUserData();
      Navigator.pop(context); // Close loading

      if (success && mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hesap silinemedi', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
