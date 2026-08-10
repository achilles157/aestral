/// Model bukti persetujuan PDP (UU 27/2022 Pasal 20-24).
/// Disimpan ke Firestore `users/{uid}/consents/{id}` atau
/// SharedPreferences untuk guest.
class ConsentLog {
  final String id;
  final ConsentType type;
  final int version;
  final DateTime grantedAt;
  final String? ipHash;

  const ConsentLog({
    required this.id,
    required this.type,
    required this.version,
    required this.grantedAt,
    this.ipHash,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'version': version,
    'grantedAt': grantedAt.toIso8601String(),
    if (ipHash != null) 'ipHash': ipHash,
  };

  factory ConsentLog.fromJson(Map<String, dynamic> json) => ConsentLog(
    id: json['id'] as String,
    type: ConsentType.values.byName(json['type'] as String),
    version: json['version'] as int,
    grantedAt: DateTime.parse(json['grantedAt'] as String),
    ipHash: json['ipHash'] as String?,
  );

  /// Versi terbaru consent per tipe.
  /// Naikkan versi setiap perubahan signifikan pada kebijakan.
  static const Map<ConsentType, int> latestVersions = {
    ConsentType.dataProcessing: 1,
    ConsentType.historyStorage: 1,
    ConsentType.analytics: 1,
  };
}

/// Tiga jenis izin sesuai PDP.
enum ConsentType {
  /// Izin 1: pemrosesan data profil (tanggal lahir, hasil reading)
  dataProcessing,

  /// Izin 2: penyimpanan riwayat (hanya pengguna login)
  historyStorage,

  /// Izin 3: analitik (opsional)
  analytics,
}

extension ConsentTypeLabel on ConsentType {
  String get title {
    switch (this) {
      case ConsentType.dataProcessing:
        return 'Pemrosesan Data Profil';
      case ConsentType.historyStorage:
        return 'Penyimpanan Riwayat';
      case ConsentType.analytics:
        return 'Analitik (Opsional)';
    }
  }

  String get description {
    switch (this) {
      case ConsentType.dataProcessing:
        return 'Kami menggunakan tanggal lahir dan hasil pembacaan'
            ' weton/BaZi/tarot Anda untuk personalisasi pengalaman.'
            ' Data ini diproses secara lokal dan melalui AI (Gemini)'
            ' untuk menghasilkan insight yang relevan.';
      case ConsentType.historyStorage:
        return 'Riwayat pembacaan dan percakapan AI Anda disimpan'
            ' agar bisa diakses kembali. Hanya Anda yang bisa'
            ' melihat riwayat ini.';
      case ConsentType.analytics:
        return 'Data penggunaan anonim (halaman dibuka, fitur'
            ' digunakan) untuk membantu kami memahami apa yang'
            ' bermanfaat. Tidak terkait identitas Anda.';
    }
  }

  /// `true` = wajib; `false` = opsional.
  bool get isRequired => this != ConsentType.analytics;
}
