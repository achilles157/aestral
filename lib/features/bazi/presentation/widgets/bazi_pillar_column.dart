import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';

/// Element accent colors — consistent across all Ba Zi widgets.
const Map<String, Color> kBaziElementColors = {
  'kayu':  Color(0xFF4ADE80),
  'api':   Color(0xFFF87171),
  'tanah': Color(0xFFFBBF24),
  'logam': Color(0xFFE2E8F0),
  'air':   Color(0xFF60A5FA),
};

const Map<String, String> kBaziElementEmoji = {
  'kayu':  '🌿',
  'api':   '🔥',
  'tanah': '🪨',
  'logam': '⚔️',
  'air':   '💧',
};

/// Cang Gan (藏干) — hidden stems per Earthly Branch.
const Map<String, List<String>> _kCangGan = {
  'zi':   ['gui'],
  'chou': ['ji', 'gui', 'xin'],
  'yin':  ['jia', 'bing', 'wu'],
  'mao':  ['yi'],
  'chen': ['wu', 'yi', 'gui'],
  'si':   ['bing', 'wu', 'geng'],
  'wu':   ['ding', 'ji'],
  'wei':  ['ji', 'ding', 'yi'],
  'shen': ['geng', 'ren', 'wu'],
  'you':  ['xin'],
  'xu':   ['wu', 'xin', 'ding'],
  'hai':  ['ren', 'jia'],
};

const Map<String, String> _kStemSymbol = {
  'jia': '甲', 'yi': '乙', 'bing': '丙', 'ding': '丁', 'wu': '戊',
  'ji':  '己', 'geng': '庚', 'xin': '辛', 'ren': '壬', 'gui': '癸',
};

const Map<String, String> _kStemElement = {
  'jia': 'kayu', 'yi':   'kayu',  'bing': 'api',   'ding': 'api',
  'wu':  'tanah', 'ji':  'tanah', 'geng': 'logam', 'xin':  'logam',
  'ren': 'air',   'gui': 'air',
};

const _kElementDesc = {
  'kayu':  'Elemen Pertumbuhan — fleksibel, kreatif, selalu berencana ke depan. Kayu melambangkan dorongan untuk terus berkembang dan memperluas.',
  'api':   'Elemen Transformasi — ekspresif, hangat, memimpin dengan semangat. Api mewakili energi yang mengubah dan menerangi.',
  'tanah': 'Elemen Stabilitas — dapat dipercaya, praktis, kemampuan memelihara yang kuat. Tanah adalah fondasi yang menopang semua elemen lain.',
  'logam': 'Elemen Ketegasan — presisi, disiplin, mampu memotong hal yang tidak esensial. Logam mewakili kemampuan menyempurnakan dan mempertajam.',
  'air':   'Elemen Adaptasi — intuisi dalam, kebijaksanaan laten, mengalir dengan perubahan. Air melambangkan kemampuan menemukan jalan di tengah rintangan.',
};

/// Deskripsi spesifik per Heavenly Stem (10 batang langit).
const _kStemDesc = {
  'jia':  'Pohon besar yang tegak — jiwa pelopor yang membuka jalan baru. Jia memiliki tekad kuat dan naluri kepemimpinan alami, namun butuh akar yang kuat agar tidak mudah terombang-ambing.',
  'yi':   'Tanaman merambat yang fleksibel — adaptif dan ulet. Yi menemukan jalan di celah sempit, membangun jaringan relasi dengan lembut namun kuat.',
  'bing': 'Matahari yang bersinar — energi ekspansif dan karismatik. Bing menerangi semua yang ada di sekitarnya, membawa kehangatan dan vitalitas yang bisa dirasakan semua orang.',
  'ding': 'Api lilin yang teguh — intens namun terarah. Ding memiliki kedalaman batin dan fokus yang kuat, menyalakan inspirasi di ruang-ruang yang lebih intim.',
  'wu':   'Gunung yang kokoh — penyangga dan pelindung. Wu memberi fondasi yang stabil bagi orang-orang di sekitarnya, teguh dan dapat diandalkan di segala kondisi.',
  'ji':   'Ladang subur yang memelihara — penuh perhatian dan nurturing. Ji menyerap dan mentransformasi energi di sekitarnya, menumbuhkan potensi orang lain dengan sabar.',
  'geng': 'Pedang yang tajam — tegas, langsung, dan berani. Geng memiliki tekad untuk memangkas yang tidak perlu dan mempertahankan apa yang benar.',
  'xin':  'Perhiasan yang halus — detail, perfeksionis, dan estetis. Xin menemukan keindahan dalam presisi dan memiliki standar tinggi terhadap diri sendiri.',
  'ren':  'Samudra yang luas — kapasitas besar untuk mengandung dan memahami. Ren berpikir dalam skala besar, visioner, dan mampu menampung berbagai perspektif.',
  'gui':  'Embun dan hujan yang menyuburkan — intuitif dan sensitif. Gui membawa kebijaksanaan dari alam bawah sadar, merasakan arus yang tersembunyi di balik permukaan.',
};

/// Deskripsi spesifik per Earthly Branch (12 cabang bumi).
const _kBranchDesc = {
  'zi':   'Malam yang dalam, awal dari siklus baru. Energi Air yang tersembunyi membawa intuisi tajam dan kemampuan untuk memulai dari nol.',
  'chou': 'Kerja keras yang dibangun dalam keheningan. Energi Tanah Yin yang ulet dan tekun, fondasi kuat yang tidak terlihat namun selalu terasa.',
  'yin':  'Kebangkitan awal musim semi, dorongan kuat ke depan. Energi Kayu Yang yang berani dan penuh inisiatif, tidak takut melangkah pertama.',
  'mao':  'Pertumbuhan lembut yang tak terbendung. Energi Kayu Yin yang fleksibel namun gigih, menembus celah sempit dengan tekad yang tenang.',
  'chen': 'Transformasi dan transisi — momen di mana semua bisa berubah. Tanah Yang yang menyimpan potensi Air dan Kayu, titik pivot antara musim.',
  'si':   'Kedalaman dan transformasi tersembunyi. Energi Api Yin yang membakar di dalam, membawa kebijaksanaan yang didapat dari pengalaman yang mendalam.',
  'wu':   'Puncak api dan semangat yang membara. Energi Api Yang yang ekspresif dan penuh vitalitas, momentum terkuat dalam siklus tahunan.',
  'wei':  'Kelembutan di tengah panas. Energi Tanah Yin yang memelihara, jembatan antara puncak musim panas dan awal transisi musim gugur.',
  'shen': 'Kecerdasan dan ketangkasan yang tinggi. Energi Logam Yang yang adaptif, mampu memecahkan masalah dengan cara yang tidak terduga.',
  'you':  'Ketepatan dan kemurnian. Energi Logam Yin yang penuh detail, mencari kesempurnaan dalam setiap hal yang dilakukan.',
  'xu':   'Kesetiaan dan penjagaan. Tanah Yang yang menyimpan Api dan Logam — siap berubah total di penghujung siklus menuju yang baru.',
  'hai':  'Penutup siklus yang penuh kebijaksanaan. Energi Air Yang yang membawa dalam dirinya benih siklus berikutnya, kembali ke keheningan.',
};

/// Pengucapan pinyin per Heavenly Stem.
const _kStemPinyin = {
  'jia': 'Jiǎ', 'yi': 'Yǐ', 'bing': 'Bǐng', 'ding': 'Dīng', 'wu': 'Wù',
  'ji': 'Jǐ', 'geng': 'Gēng', 'xin': 'Xīn', 'ren': 'Rén', 'gui': 'Guǐ',
};

/// Pengucapan pinyin per Earthly Branch.
const _kBranchPinyin = {
  'zi': 'Zǐ', 'chou': 'Chǒu', 'yin': 'Yín', 'mao': 'Mǎo',
  'chen': 'Chén', 'si': 'Sì', 'wu': 'Wǔ', 'wei': 'Wèi',
  'shen': 'Shēn', 'you': 'Yǒu', 'xu': 'Xū', 'hai': 'Hài',
};

/// A single vertical pillar column showing Heavenly Stem above Earthly Branch.
///
/// Used inside [BaziFourPillarsChart]. Pass [pillar] = null to render the
/// "Jam tidak diketahui" placeholder.
class BaziPillarColumn extends StatelessWidget {
  final String label;
  final BaziPillar? pillar;
  final bool isHighlighted; // true for Day Pillar (Day Master emphasis)
  final int? dayMasterStemIndex;

  const BaziPillarColumn({
    super.key,
    required this.label,
    required this.pillar,
    this.isHighlighted = false,
    this.dayMasterStemIndex,
  });

  @override
  Widget build(BuildContext context) {
    final Color elementColor = pillar != null
        ? (kBaziElementColors[pillar!.element] ?? AppTheme.accentGold)
        : Colors.white24;

    final Color glowColor = elementColor.withValues(alpha: 0.18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? elementColor : elementColor.withValues(alpha: 0.4),
          width: isHighlighted ? 1.5 : 0.8,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: glowColor, blurRadius: 18, spreadRadius: 2)]
            : [BoxShadow(color: glowColor, blurRadius: 8)],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pillar label (Tahun / Bulan / Hari / Jam)
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: elementColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (pillar != null) ...[
            // Heavenly Stem symbol — tap for detail
            GestureDetector(
              onTap: () => _showStemSheet(context, pillar!, elementColor),
              child: Column(children: [
                Text(
                  pillar!.stemSymbol,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    color: elementColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pillar!.stemNameId,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.white70,
                    height: 1.2,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Divider(color: elementColor.withValues(alpha: 0.25), height: 1),
            const SizedBox(height: 10),
            // Earthly Branch symbol — tap for detail
            GestureDetector(
              onTap: () => _showBranchSheet(context, pillar!, elementColor),
              child: Column(children: [
                Text(
                  pillar!.branchSymbol,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    color: elementColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pillar!.branchZodiacId,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.white60,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                _CangGanRow(branchId: pillar!.branchId),
              ]),
            ),
            const SizedBox(height: 6),
            // Sexagenary slug pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: elementColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: elementColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                pillar!.id.replaceAll('_', ' '),
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  color: elementColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ] else ...[
            // Unknown hour placeholder
            const SizedBox(height: 8),
            Text(
              '？',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak\nDiketahui',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white30,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
  void _showStemSheet(BuildContext context, BaziPillar pillar, Color color) {
    final pinyin = _kStemPinyin[pillar.stemId] ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PillarPartSheet(
        symbol: pillar.stemSymbol,
        title: pillar.stemNameId,
        subtitle: pinyin.isNotEmpty
            ? '$pinyin · Heavenly Stem · ${pillar.element}'
            : 'Heavenly Stem · ${pillar.element}',
        description: _kStemDesc[pillar.stemId] ?? _kElementDesc[pillar.element] ?? '',
        color: color,
        dayMasterStemIndex: dayMasterStemIndex,
      ),
    );
  }

  void _showBranchSheet(BuildContext context, BaziPillar pillar, Color color) {
    final hiddenStems = _kCangGan[pillar.branchId] ?? [];
    final pinyin = _kBranchPinyin[pillar.branchId] ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PillarPartSheet(
        symbol: pillar.branchSymbol,
        title: pillar.branchZodiacId,
        subtitle: pinyin.isNotEmpty
            ? '$pinyin · Earthly Branch · ${pillar.element}'
            : 'Earthly Branch · ${pillar.element}',
        description: _kBranchDesc[pillar.branchId] ?? _kElementDesc[pillar.element] ?? '',
        color: color,
        hiddenStems: hiddenStems,
        dayMasterStemIndex: dayMasterStemIndex,
      ),
    );
  }
}

/// Compact row of hidden stem (藏干) symbols, each tinted by element color.
class _CangGanRow extends StatelessWidget {
  final String branchId;
  const _CangGanRow({required this.branchId});

  @override
  Widget build(BuildContext context) {
    final stems = _kCangGan[branchId] ?? [];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stems.map((s) {
        final Color c = kBaziElementColors[_kStemElement[s]] ?? Colors.white24;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            _kStemSymbol[s] ?? '',
            style: TextStyle(
              fontSize: 9,
              color: c.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

const Map<String, String> _kTenGodNamesShort = {
  'friend':            'Sahabat',
  'rob_wealth':        'Penantang',
  'eating_god':        'Pencipta',
  'hurting_officer':   'Visioner',
  'indirect_wealth':   'Jaring',
  'direct_wealth':     'Pembangun',
  'seven_killings':    'Pendobrak',
  'direct_officer':    'Penjaga',
  'indirect_resource': 'Filsuf',
  'direct_resource':   'Pustaka',
};

class _PillarPartSheet extends StatelessWidget {
  final String symbol;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final List<String> hiddenStems;
  final int? dayMasterStemIndex;

  const _PillarPartSheet({
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    this.hiddenStems = const [],
    this.dayMasterStemIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(symbol,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 52, color: color, fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textMuted)),
            ]),
          ]),
          const SizedBox(height: 14),
          Text(description,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textLight, height: 1.5)),
          if (hiddenStems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('藏干 · Hidden Stems',
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: hiddenStems.map((s) {
                final c = kBaziElementColors[_kStemElement[s]] ?? Colors.white38;
                
                String labelText = '${_kStemSymbol[s] ?? ''} ${_kStemElement[s] ?? s}';
                if (dayMasterStemIndex != null) {
                  final targetStemIdx = BaziUtils.stemIds.indexOf(s);
                  if (targetStemIdx != -1) {
                    final godId = BaziUtils.getTenGodId(dayMasterStemIndex!, targetStemIdx);
                    final godName = _kTenGodNamesShort[godId] ?? godId;
                    labelText += ' ($godName)';
                  }
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    labelText,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: c, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
