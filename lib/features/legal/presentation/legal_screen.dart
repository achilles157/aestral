import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Jenis dokumen legal yang ditampilkan.
enum LegalDocumentType { privacyPolicy, termsOfService }

/// Layar dokumen legal (Kebijakan Privasi / Syarat Layanan).
///
/// Konten dimuat dari asset markdown (`assets/legal/`) — satu sumber
/// kebenaran yang sama dengan `docs/legal/` di repo.
class LegalScreen extends StatefulWidget {
  final LegalDocumentType type;

  const LegalScreen({super.key, required this.type});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final asset = switch (widget.type) {
        LegalDocumentType.privacyPolicy => 'assets/legal/privacy-policy.md',
        LegalDocumentType.termsOfService => 'assets/legal/terms-of-service.md',
      };
      final raw = await rootBundle.loadString(asset);
      if (!mounted) return;
      setState(() {
        _content = raw;
        _loading = false;
      });
    } catch (e) {
      debugPrint('LegalScreen load error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat dokumen. Coba lagi nanti.';
        _loading = false;
      });
    }
  }

  String get _title => switch (widget.type) {
    LegalDocumentType.privacyPolicy => 'Kebijakan Privasi',
    LegalDocumentType.termsOfService => 'Syarat Layanan',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _title,
          style: GoogleFonts.cinzel(
            color: AppTheme.accentGold,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: const Text(
                'Coba lagi',
                style: TextStyle(color: AppTheme.accentGold),
              ),
            ),
          ],
        ),
      );
    }
    return Markdown(
      data: _content ?? '',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        h2: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.accentGold,
        ),
        h3: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        p: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.88),
          height: 1.6,
        ),
        listBullet: GoogleFonts.outfit(
          fontSize: 14,
          color: AppTheme.accentGold,
        ),
        blockquote: GoogleFonts.outfit(
          fontSize: 13.5,
          color: AppTheme.accentGold,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: const Color(0xFF151226),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: AppTheme.accentGold, width: 3),
          ),
        ),
        tableHead: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        tableBody: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.88),
        ),
        tableBorder: TableBorder.all(color: Colors.white12),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
