/// Item glosarium istilah astrologi — dimuat dari `assets/glosarium.json`.
class GlosariumItem {
  final String id;
  final String istilah;
  final String domain; // weton | bazi | tarot | mangsa
  final String definisi;
  final List<String> alias;
  final String contoh;

  const GlosariumItem({
    required this.id,
    required this.istilah,
    required this.domain,
    required this.definisi,
    required this.alias,
    required this.contoh,
  });

  factory GlosariumItem.fromJson(Map<String, dynamic> json) => GlosariumItem(
    id: json['id'] as String? ?? '',
    istilah: json['istilah'] as String? ?? '',
    domain: json['domain'] as String? ?? '',
    definisi: json['definisi'] as String? ?? '',
    alias: List<String>.from(json['alias'] ?? const []),
    contoh: json['contoh'] as String? ?? '',
  );
}
