import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

/// Tooltip sekali muncul untuk panduan pengguna baru pada setiap tab.
///
/// Dipicu otomatis saat pertama kali pengguna masuk ke tab tertentu.
/// Setelah tooltip di-dismiss (ketuk area luar atau tombol "Mengerti"),
/// flag disimpan di SharedPreferences dan tidak muncul lagi untuk tab itu.
class FirstTimeTabTooltip extends ConsumerStatefulWidget {
  const FirstTimeTabTooltip({
    super.key,
    required this.tabKey,
    required this.tabLabel,
    required this.description,
    required this.icon,
    required this.child,
    this.accentColor,
  });

  final String tabKey;
  final String tabLabel;
  final String description;
  final IconData icon;
  final Widget child;
  final Color? accentColor;

  @override
  ConsumerState<FirstTimeTabTooltip> createState() =>
      _FirstTimeTabTooltipState();
}

class _FirstTimeTabTooltipState extends ConsumerState<FirstTimeTabTooltip>
    with SingleTickerProviderStateMixin {
  bool _showTooltip = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tooltip_seen_${widget.tabKey}';
    final seen = prefs.getBool(key) ?? false;
    if (seen) {
      if (mounted) setState(() => _showTooltip = false);
    } else {
      unawaited(_animCtrl.forward());
    }
  }

  Future<void> _dismiss() async {
    await _animCtrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tooltip_seen_${widget.tabKey}', true);
    if (mounted) setState(() => _showTooltip = false);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  static const Map<String, _TabHint> _hints = {
    'beranda': _TabHint(
      icon: Icons.home_rounded,
      label: 'Beranda',
      description:
          'Dashboard personalmu — lihat energi kosmis hari ini dan akses semua fitur dari sini.',
    ),
    'tarot': _TabHint(
      icon: Icons.auto_awesome,
      label: 'Tarot',
      description:
          'Tarik tiga kartu untuk melihat masa lalu, masa kini, dan masa depanmu. Kartu dipengaruhi siklus alam.',
    ),
    'weton': _TabHint(
      icon: Icons.brightness_medium_rounded,
      label: 'Weton',
      description:
          'Weton adalah sistem penanggalan Jawa yang menghitung karakter, nasib, dan kecocokanmu berdasarkan hari lahirmu.',
    ),
    'planner': _TabHint(
      icon: Icons.calendar_month_rounded,
      label: 'Planner',
      description:
          'Kalender astrologi untuk melihat hari baik, energi harian, dan panduan waktu berdasarkan wetonmu.',
    ),
    'bazi': _TabHint(
      icon: Icons.grid_4x4_rounded,
      label: 'Ba Zi',
      description:
          'Ba Zi (Eight Characters) adalah astrologi Tiongkok yang menganalisis empat pilar kelahiranmu — tahun, bulan, hari, jam.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (!_showTooltip) return widget.child;

    final hint = _hints[widget.tabKey];
    if (hint == null) return widget.child;

    final accent = widget.accentColor ?? AppTheme.accentGold;

    return Stack(
      children: [
        widget.child,
        // Dim overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            child: AnimatedBuilder(
              animation: _opacityAnim,
              builder: (context, _) {
                return Container(
                  color: Colors.black.withValues(alpha: _opacityAnim.value * 0.6),
                );
              },
            ),
          ),
        ),
        // Tooltip card
        Positioned(
          top: MediaQuery.of(context).size.height * 0.22,
          left: 24,
          right: 24,
          child: AnimatedBuilder(
            animation: _opacityAnim,
            builder: (context, _) {
              return Opacity(
                opacity: _opacityAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1535),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(hint.icon, color: accent, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selamat datang di ${hint.label} ✦',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hint.description,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _dismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Mengerti, mulai jelajah ✦',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabHint {
  final IconData icon;
  final String label;
  final String description;

  const _TabHint({
    required this.icon,
    required this.label,
    required this.description,
  });
}
