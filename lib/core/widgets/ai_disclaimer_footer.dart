import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Footer disclaimer AI — reusable di setiap hasil AI.
///
/// P3-D: Pasal perlindungan konsumen — memberitahu pengguna
/// bahwa output AI bukan nasihat profesional.
///
/// Penggunaan:
/// ```dart
/// AiDisclaimerFooter(),
/// ```
/// Atau dengan padding custom:
/// ```dart
/// AiDisclaimerFooter(padding: EdgeInsets.only(top: 12)),
/// ```
class AiDisclaimerFooter extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const AiDisclaimerFooter({
    super.key,
    this.padding = const EdgeInsets.only(top: 8),
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: fontSize + 2,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 4),
          Text(
            'Dihasilkan AI untuk refleksi & hiburan —'
            ' bukan nasihat profesional.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: fontSize,
              color: Colors.white.withValues(alpha: 0.22),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
