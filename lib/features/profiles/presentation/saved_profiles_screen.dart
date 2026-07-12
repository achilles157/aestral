import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/saved_profile.dart';
import '../services/saved_profiles_service.dart';

/// Layar manajemen profil tersimpan.
class SavedProfilesScreen extends StatefulWidget {
  /// Jika non-null, mode "pilih profil" — tap profil mengembalikan ke caller.
  final void Function(SavedProfile)? onPick;

  const SavedProfilesScreen({super.key, this.onPick});

  @override
  State<SavedProfilesScreen> createState() => _SavedProfilesScreenState();
}

class _SavedProfilesScreenState extends State<SavedProfilesScreen> {
  List<SavedProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await SavedProfilesService.load();
    if (mounted) setState(() { _profiles = profiles; _isLoading = false; });
  }

  Future<void> _delete(SavedProfile profile) async {
    await SavedProfilesService.delete(profile.id);
    setState(() => _profiles.removeWhere((p) => p.id == profile.id));
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    DateTime? picked;
    final fmt = DateFormat('d MMM yyyy', 'id_ID');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Tambah Profil',
              style: GoogleFonts.cinzel(color: AppTheme.accentGold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nama',
                  labelStyle: GoogleFonts.outfit(color: Colors.white54),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.accentGold)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime(1995, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.accentGold,
                          onPrimary: Colors.black,
                          surface: Color(0xFF1A1A2E),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) setDlg(() => picked = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: picked != null
                            ? AppTheme.accentGold.withValues(alpha: 0.5)
                            : Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16,
                          color: picked != null
                              ? AppTheme.accentGold
                              : Colors.white38),
                      const SizedBox(width: 10),
                      Text(
                        picked != null
                            ? fmt.format(picked!)
                            : 'Pilih tanggal lahir...',
                        style: GoogleFonts.outfit(
                          color: picked != null ? Colors.white : Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.outfit(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty || picked == null) return;
                final profile = SavedProfile(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  birthDate: picked!,
                  addedAt: DateTime.now(),
                );
                await SavedProfilesService.save(profile);
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: Text('Simpan',
                  style: GoogleFonts.outfit(color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPicking = widget.onPick != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isPicking ? 'Pilih Profil' : 'Profil Tersimpan',
          style: GoogleFonts.cinzel(
              color: AppTheme.accentGold,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (!isPicking)
            IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: AppTheme.accentGold, size: 22),
              onPressed: _showAddDialog,
              tooltip: 'Tambah profil',
            ),
        ],
      ),
      floatingActionButton: isPicking
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: AppTheme.accentGold,
              child: const Icon(Icons.add, color: Colors.black),
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0D2E)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGold))
            : _profiles.isEmpty
                ? _buildEmptyState()
                : _buildList(isPicking),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              color: AppTheme.accentGold.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 16),
          Text('Belum ada profil tersimpan',
              style: GoogleFonts.playfairDisplay(
                  color: Colors.white38,
                  fontSize: 15,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text(
            'Simpan profil pasangan atau keluarga\nuntuk kompatibilitas yang lebih cepat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                color: Colors.white24, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isPicking) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _profiles.length,
      itemBuilder: (ctx, i) {
        final p = _profiles[i];
        return GestureDetector(
          onTap: isPicking ? () {
            Navigator.of(context).pop();
            widget.onPick!(p);
          } : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentGold.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            p.name.isNotEmpty
                                ? p.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.cinzel(
                                color: AppTheme.accentGold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(p.formattedBirthDate,
                                style: GoogleFonts.outfit(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isPicking)
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.accentGold, size: 18)
                      else
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white30, size: 18),
                          onPressed: () => _delete(p),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
