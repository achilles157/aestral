import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ai/models/chat_message.dart';

/// Merender OracleCard ke dalam widget yang sesuai berdasarkan tipe.
/// Dibungkus try-catch sehingga kegagalan parsing tidak crash aplikasi.
Widget buildOracleCard(OracleCard card, Color accentColor) {
  try {
    switch (card.type) {
      case 'checklist':
        return _ChecklistCard(data: card.data, accentColor: accentColor);
      case 'element_bar':
        return _ElementBarCard(data: card.data, accentColor: accentColor);
      case 'key_insight':
        return _KeyInsightCard(data: card.data, accentColor: accentColor);
      default:
        return const SizedBox.shrink();
    }
  } catch (_) {
    return const SizedBox.shrink();
  }
}

// ── Checklist Card ────────────────────────────────────────────────────────────

class _ChecklistCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color accentColor;

  const _ChecklistCard({required this.data, required this.accentColor});

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  late List<bool> _checked;
  late String _storageKey;

  @override
  void initState() {
    super.initState();
    final items = _getItems();
    _checked = List.filled(items.length, false);
    // Key berdasarkan hash konten agar unik per checklist yang berbeda
    _storageKey = 'oracle_checklist_${items.join('|').hashCode}';
    _loadCheckedState();
  }

  Future<void> _loadCheckedState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && mounted) {
      final decoded = (json.decode(saved) as List).cast<bool>();
      if (decoded.length == _checked.length) {
        setState(() => _checked = decoded);
      }
    }
  }

  Future<void> _saveCheckedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(_checked));
  }

  List<String> _getItems() {
    final raw = widget.data['items'];
    if (raw is List) return raw.cast<String>();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    final title = widget.data['title'] as String? ?? 'Panduan Hari Ini';

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: widget.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.accentColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(items.length, (i) {
            return InkWell(
                onTap: () {
                  setState(() => _checked[i] = !_checked[i]);
                  _saveCheckedState();
                },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _checked[i]
                            ? widget.accentColor.withValues(alpha: 0.9)
                            : Colors.transparent,
                        border: Border.all(
                          color: _checked[i]
                              ? widget.accentColor
                              : Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: _checked[i]
                          ? Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(
                              alpha: _checked[i] ? 0.4 : 0.85),
                          decoration: _checked[i]
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Element Bar Card ──────────────────────────────────────────────────────────

class _ElementBarCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accentColor;

  const _ElementBarCard({required this.data, required this.accentColor});

  static const Map<String, Color> _elementColors = {
    'Kayu': Color(0xFF66BB6A),
    'Api': Color(0xFFEF5350),
    'Tanah': Color(0xFFFFCA28),
    'Logam': Color(0xFFBDBDBD),
    'Air': Color(0xFF42A5F5),
  };

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Keseimbangan Elemen';
    final elements = data['elements'];
    if (elements is! Map) return const SizedBox.shrink();

    final bars = elements.entries.map((e) {
      final name = e.key as String;
      final value = (e.value as num?)?.toDouble() ?? 0.0;
      final color = _elementColors[name] ?? accentColor;
      return (name: name, value: value.clamp(0.0, 10.0), color: color);
    }).toList();

    if (bars.isEmpty) return const SizedBox.shrink();

    final maxVal = bars.fold(0.0, (m, b) => b.value > m ? b.value : m);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bars.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        b.name,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, constraints) {
                        final pct = maxVal > 0 ? (b.value / maxVal) : 0.0;
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              height: 8,
                              width: constraints.maxWidth * pct,
                              decoration: BoxDecoration(
                                color: b.color,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: b.color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      b.value.toStringAsFixed(0),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: b.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Key Insight Card ──────────────────────────────────────────────────────────

class _KeyInsightCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accentColor;

  const _KeyInsightCard({required this.data, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Pesan Kesadaran';
    final insight = data['insight'] as String? ?? '';

    if (insight.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.92),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
