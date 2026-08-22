import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Halaman Kebijakan Privasi — sesuai UU 27/2022 (PDP).
/// Statis, offline, bahasa Indonesia.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String route = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        '1. Pendahuluan',
                        'Aestral ("kami") berkomitmen melindungi privasi Anda'
                            ' sesuai Undang-Undang No. 27 Tahun 2022 tentang'
                            ' Pelindungan Data Pribadi (UU PDP). Kebijakan ini'
                            ' menjelaskan bagaimana kami mengumpulkan,'
                            ' menggunakan, dan melindungi data Anda.',
                      ),
                      _section(
                        '2. Data yang Kami Kumpulkan',
                        '• Tanggal lahir, waktu lahir, dan jenis kelamin'
                            ' (untuk kalkulasi Weton & Ba Zi)\n'
                            '• Hasil pembacaan (Weton, Ba Zi, Tarot)\n'
                            '• Riwayat percakapan dengan oracle AI\n'
                            '• Data penggunaan anonim (jika Anda setuju)\n'
                            '• Informasi akun Google (jika login via Google)',
                      ),
                      _section(
                        '3. Dasar Pemrosesan',
                        'Kami memproses data Anda berdasarkan:\n'
                            '• Persetujuan eksplisit (Pasal 20 UU PDP)\n'
                            '• Kepentingan yang sah untuk memberikan layanan\n'
                            '• Kepatuhan terhadap kewajiban hukum',
                      ),
                      _section(
                        '4. Tujuan Pemrosesan',
                        'Data Anda digunakan untuk:\n'
                            '• Menghasilkan pembacaan weton, Ba Zi, dan tarot'
                            ' yang dipersonalisasi\n'
                            '• Menyimpan riwayat pembacaan agar bisa diakses'
                            ' kembali\n'
                            '• Meningkatkan kualitas layanan (analitik,'
                            ' jika diizinkan)',
                      ),
                      _section(
                        '5. Penyimpanan & Keamanan',
                        '• Data disimpan di Google Firebase (Firestore)\n'
                            '• Enkripsi data in-transit (HTTPS)\n'
                            '• Akses data dibatasi per pengguna (Firestore'
                            ' Security Rules)\n'
                            '• Guest/tamu tanpa login: data hanya disimpan'
                            ' lokal di perangkat',
                      ),
                      _section(
                        '6. Hak Subjek Data (Pasal 5-13 UU PDP)',
                        'Anda memiliki hak:\n'
                            '• Mengakses data Anda\n'
                            '• Mengoreksi data yang tidak akurat\n'
                            '• Menghapus akun & seluruh data\n'
                            '• Menarik kembali persetujuan (consent)\n'
                            '• Mengekspor data dalam format yang bisa dibaca'
                            ' mesin\n\n'
                            'Hubungi kami di: privacy@aestral.app',
                      ),
                      _section(
                        '7. Retensi Data',
                        '• Data disimpan selama akun Anda aktif\n'
                            '• Setelah penghapusan akun, data dihapus dalam'
                            ' 30 hari\n'
                            '• Data guest (tanpa login) bertahan selama'
                            ' aplikasi terinstal',
                      ),
                      _section(
                        '8. AI & Otomatisasi',
                        'Aestral menggunakan Google Gemini AI untuk'
                            ' menghasilkan insight. Semua output AI bersifat'
                            ' untuk refleksi dan hiburan — BUKAN nasihat'
                            ' profesional, medis, keuangan, atau hukum.'
                            ' Data yang dikirim ke AI adalah data yang sudah'
                            ' Anda setujui untuk diproses.',
                      ),
                      _section(
                        '9. Perubahan Kebijakan',
                        'Kami dapat memperbarui kebijakan ini sewaktu-waktu.'
                            ' Perubahan signifikan akan diberitahukan melalui'
                            ' aplikasi. Versi terbaru selalu tersedia di'
                            ' halaman ini.',
                      ),
                      _section(
                        '10. Kontak',
                        'Untuk pertanyaan tentang privasi:\n'
                            '📧 privacy@aestral.app\n\n'
                            'Terakhir diperbarui: Agustus 2026',
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Kebijakan Privasi',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
