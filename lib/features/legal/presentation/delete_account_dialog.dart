import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';

/// Dialog konfirmasi 2 langkah sebelum hapus akun.
/// P3-B: Langkah 1 = dialog peringatan, Langkah 2 = ketik "HAPUS".
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  int _step = 1;
  bool _deleting = false;
  String? _error;
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeDelete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider.notifier);
      await auth.deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _deleting = false;
        _error = 'Gagal menghapus akun. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            _step == 1 ? Icons.warning_amber_rounded : Icons.delete_forever,
            color: AppTheme.error,
          ),
          const SizedBox(width: 10),
          Text(
            _step == 1 ? 'Hapus Akun?' : 'Konfirmasi Penghapusan',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: AppTheme.textLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: _step == 1 ? _buildStep1() : _buildStep2(),
      actions: _buildActions(),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tindakan ini TIDAK BISA DIURUNGKAN.',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppTheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Data yang akan dihapus:\n'
          '• Profil & semua data pribadi\n'
          '• Riwayat pembacaan Weton, BaZi, & Tarot\n'
          '• Semua percakapan dengan oracle\n'
          '• Log persetujuan (consent)',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ketik "HAPUS" di bawah untuk mengonfirmasi:',
          style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmCtrl,
          style: GoogleFonts.outfit(
            color: AppTheme.error,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'HAPUS',
            hintStyle: GoogleFonts.outfit(
              color: Colors.white24,
              letterSpacing: 4,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
        child: Text(
          _step == 1 ? 'Batal' : 'Kembali',
          style: GoogleFonts.outfit(color: AppTheme.textMuted),
        ),
      ),
      if (_step == 1)
        TextButton(
          onPressed: _deleting ? null : () => setState(() => _step = 2),
          child: Text(
            'Lanjutkan',
            style: GoogleFonts.outfit(
              color: AppTheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
      else
        TextButton(
          onPressed:
              (_deleting || _confirmCtrl.text.trim().toUpperCase() != 'HAPUS')
              ? null
              : _executeDelete,
          child: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.error,
                  ),
                )
              : Text(
                  'Hapus Permanen',
                  style: GoogleFonts.outfit(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
    ];
  }
}

