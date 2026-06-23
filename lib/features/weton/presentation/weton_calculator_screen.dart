import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import '../services/weton_dictionary_service.dart';
import 'components/weton_detail_card.dart';

class WetonCalculatorScreen extends ConsumerStatefulWidget {
  const WetonCalculatorScreen({super.key});

  @override
  ConsumerState<WetonCalculatorScreen> createState() => _WetonCalculatorScreenState();
}

class _WetonCalculatorScreenState extends ConsumerState<WetonCalculatorScreen> {
  DateTime? _selectedDate;
  WetonInfo? _result;

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentPurple,
              onPrimary: AppTheme.textLight,
              surface: AppTheme.cardBg,
              onSurface: AppTheme.textLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _result = WetonUtils.calculateWeton(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dictionaryAsync = ref.watch(wetonDictionaryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Primbon Weton',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  Color(0xFF130E30),
                  Color(0xFF0A0618),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pahami watak bawaan lahir dan elemen spiritual Anda berdasarkan keselarasan kalender Jawa.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Date picker card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'PILIH TANGGAL LAHIR',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _presentDatePicker,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.accentPurple, width: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month, color: AppTheme.accentPurple),
                              label: Text(
                                _selectedDate == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                                style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Calculation Results
                    if (_result != null)
                      dictionaryAsync.when(
                        data: (dictionary) {
                          final wetonName = '${_result!.saptawara} ${_result!.pancawara}';
                          final entry = lookupWetonEntry(dictionary, wetonName);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Weton Header Title
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'WETON LAHIR',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      wetonName,
                                      style: textTheme.displayLarge?.copyWith(
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    if (entry != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '"${entry.headline}"',
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.accentGold.withOpacity(0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (entry != null) ...[
                                // 3 Main Cards
                                WetonDetailCard(
                                  title: 'Karier & Rezeki',
                                  content: entry.karirRezeki,
                                  icon: Icons.work_outline,
                                  accentColor: AppTheme.accentGold,
                                ),
                                WetonDetailCard(
                                  title: 'Asmara & Hubungan',
                                  content: entry.asmaraHubungan,
                                  icon: Icons.favorite_border,
                                  accentColor: AppTheme.accentPink,
                                ),
                                WetonDetailCard(
                                  title: 'Sisi Gelap & Peringatan',
                                  content: entry.sisiGelapPeringatan,
                                  icon: Icons.warning_amber_outlined,
                                  accentColor: const Color(0xFFF87171), // Border kemerahan/kuning tua
                                ),
                              ] else ...[
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text(
                                      'Data kamus untuk weton ini tidak ditemukan.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              // Dropdown Accordion for Technical Details
                              Card(
                                child: ExpansionTile(
                                  title: Text(
                                    '🔬 Lihat Detail Perhitungan Teknis',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontSize: 16,
                                      color: AppTheme.accentPurple,
                                    ),
                                  ),
                                  collapsedIconColor: AppTheme.accentPurple,
                                  iconColor: AppTheme.accentPurple,
                                  childrenPadding: const EdgeInsets.all(20.0),
                                  children: [
                                    _DetailRow(
                                      label: 'Kalender Jawa Asapon',
                                      value: '${_result!.javaneseDay} ${_result!.javaneseMonth} ${_result!.javaneseYear} (${_result!.javaneseYearName})',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: 'Wuku', value: _result!.wuku),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: 'Neptu Saptawara', value: '${_result!.saptawara} (${_result!.neptuSaptawara})'),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: 'Neptu Pancawara', value: '${_result!.pancawara} (${_result!.neptuPancawara})'),
                                    const SizedBox(height: 20),
                                    // Neptu composite progress bar
                                    Text(
                                      'TOTAL NEPTU: ${_result!.totalNeptu} / 18',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: _result!.totalNeptu / 18,
                                        backgroundColor: AppTheme.background,
                                        color: AppTheme.accentPurple,
                                        minHeight: 10,
                                      ),
                                    ),
                                    const Divider(color: Color(0xFF2E2452), height: 40, thickness: 1.5),
                                    _AnalysisBadge(label: 'Pangarasan', value: _result!.pangarasan, color: AppTheme.accentPurple),
                                    const SizedBox(height: 12),
                                    _AnalysisBadge(label: 'Pancasuda', value: _result!.pancasuda, color: AppTheme.accentPink),
                                    const Divider(color: Color(0xFF2E2452), height: 40, thickness: 1.5),
                                    // Firestore flat JSON preview
                                    _JsonPreviewSection(result: _result!),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(color: AppTheme.accentPurple),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'Gagal memuat kamus weton: $err',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalysisBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonPreviewSection extends StatelessWidget {
  final WetonInfo result;

  const _JsonPreviewSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(result.toJson());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREVIEW DOKUMEN FIRESTORE (FLATTENED)',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2E2452)),
          ),
          child: SelectableText(
            jsonStr,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              color: AppTheme.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}
