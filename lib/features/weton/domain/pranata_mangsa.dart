class PranataMangsaModel {
  final int id;
  final String namaMangsa;
  final String namaLain;
  final String tanggalSiklus;
  final String candraMangsa;
  final String arketipeModern;
  final String karakterEnergi;
  final String ramalanKarier;
  final String ramalanAsmara;
  final String pesanKesadaran;
  final List<String> saranAktivitas;
  final String tandaAlam;

  const PranataMangsaModel({
    required this.id,
    required this.namaMangsa,
    required this.namaLain,
    required this.tanggalSiklus,
    required this.candraMangsa,
    required this.arketipeModern,
    required this.karakterEnergi,
    required this.ramalanKarier,
    required this.ramalanAsmara,
    required this.pesanKesadaran,
    required this.saranAktivitas,
    required this.tandaAlam,
  });

  factory PranataMangsaModel.fromJson(Map<String, dynamic> json) {
    return PranataMangsaModel(
      id: json['id'] as int,
      namaMangsa: json['nama_mangsa'] as String,
      namaLain: json['nama_lain'] as String,
      tanggalSiklus: json['tanggal_siklus'] as String,
      candraMangsa: json['candra_mangsa'] as String,
      arketipeModern: json['arketipe_modern'] as String,
      karakterEnergi: json['karakter_energi'] as String,
      ramalanKarier: json['ramalan_karier'] as String,
      ramalanAsmara: json['ramalan_asmara'] as String,
      pesanKesadaran: json['pesan_kesadaran'] as String,
      saranAktivitas: (json['saran_aktivitas'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tandaAlam: json['tanda_alam'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_mangsa': namaMangsa,
      'nama_lain': namaLain,
      'tanggal_siklus': tanggalSiklus,
      'candra_mangsa': candraMangsa,
      'arketipe_modern': arketipeModern,
      'karakter_energi': karakterEnergi,
      'ramalan_karier': ramalanKarier,
      'ramalan_asmara': ramalanAsmara,
      'pesan_kesadaran': pesanKesadaran,
      'saran_aktivitas': saranAktivitas,
      'tanda_alam': tandaAlam,
    };
  }
}
