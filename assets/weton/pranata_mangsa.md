# Riset Pranata Mangsa (Siklus Bulanan/Musiman Jawa) - Merged Master

Dokumen ini merupakan penggabungan hasil analisis teoritis kalender surya Jawa (Pranata Mangsa) guna mengintegrasikan sistem musiman ke dalam arsitektur aplikasi Aestral secara otentik dan presisi.

---

## BAGIAN 1: LOGIKA KALKULASI & RUMUS TANGGAL

### A. Sejarah & Tabel Patokan Tanggal Masehi (Gregorian)

Pranata Mangsa adalah sistem penanggalan matahari (*solar calendar*) Jawa yang membagi satu tahun (365/366 hari) menjadi 12 musim dengan durasi tidak seragam. Sistem ini dibakukan pada masa **Sunan Paku Buwono VII (Kerajaan Surakarta)** dan mulai resmi digunakan sejak **22 Juni 1856**. Satu siklus Pranata Mangsa dimulai pada **22 Juni** (solstis musim panas) dan berakhir pada **21 Juni** tahun berikutnya.

Berikut tabel patokan tanggal Masehi dan nama sansekerta asli untuk ke-12 Mangsa beserta Candra (watak filosofis) aslinya yang telah dilengkapi secara komprehensif:

| No | Nama Mangsa | Nama Lain (Sansekerta) | Umur (Hari) | Tanggal Mulai | Tanggal Berakhir | Candra (Watak) & Makna Filosofis Asli |
| :---: | :--- | :--- | :---: | :--- | :--- | :--- |
| 1 | **Kasa** | Kartika | 41 | 22 Juni | 1 Agustus | *Sotya murca saking embanan* (Permata terlepas dari wadahnya) |
| 2 | **Karo** | Pusa | 23 | 2 Agustus | 24 Agustus | *Bantala rengka* (Tanah retak berbongkah) |
| 3 | **Katiga** | Mangasri | 24 | 25 Agustus | 17 September | *Suta manut ing bapa* (Anak patuh pada ayah) |
| 4 | **Kapat** | Sitra | 25 | 18 September | 12 Oktober | *Waspa kumembeng jroning kalbu* (Air mata menggenang dalam hati/netra) |
| 5 | **Kalima** | Manggakala | 27 | 13 Oktober | 8 November | *Pancuran emas sumawur ing jagat* (Pancuran emas tersebar di bumi) |
| 6 | **Kanem** | Naya | 43 | 9 November | 21 Desember | *Rasa mulya kasucen* (Rasa kemuliaan dan kesucian) |
| 7 | **Kapitu** | Palguna | 43 | 22 Desember | 2 Februari | *Wisa kentar ing maruta* (Racun hanyut terbawa angin) |
| 8 | **Kawolu** | Wisaka | 26/27* | 3 Februari | 28 Februari | *Anjrah jroning kayun* (Tersebar merata di dalam hati) |
| 9 | **Kasanga** | Jita | 25 | 1 Maret | 25 Maret | *Wedharing wacana mulya* (Tersebarnya perkataan/kabar mulia) |
| 10 | **Kasepuluh** | Srawana | 24 | 26 Maret | 18 April | *Gedhong mineb jroning kalbu* (Gedung terkunci di dalam hati) |
| 11 | **Dhesta** | Pandrawana | 23 | 19 April | 11 Mei | *Sotya sinar angrengga wicara* (Permata bersinar menghiasi ucapan) |
| 12 | **Sada** | Asuji | 41 | 12 Mei | 21 Juni | *Tirta sah saking sasana* (Air meninggalkan tempatnya) |

> [!NOTE]
> Pada Mangsa **Kawolu**, umur siklus adalah 26 atau 27 hari tergantung tahun kabisat (*wastu*). Jika angka tahun Masehi habis dibagi 4, maka umurnya adalah 27 hari (berakhir di 29 Februari); jika tidak, umurnya 26 hari (berakhir di 28 Februari).

---

### B. Algoritma Penentuan ID Pranata Mangsa

Karena tanggal transisi Pranata Mangsa semi-statis terhadap kalender Gregorian, penentuan ID Mangsa dari input tanggal dapat diselesaikan secara efisien menggunakan logika perbandingan tanggal.

#### Python-style Reference Implementation:
```python
def get_pranata_mangsa(tanggal, bulan, tahun=2024):
    # Menentukan tahun kabisat untuk penyesuaian Mangsa Kawolu
    is_kabisat = (tahun % 4 == 0)
    
    # Pemetaan batas tanggal akhir untuk masing-masing mangsa
    batas = {
        1: (1, 8),    # Kasa: 1 Agustus
        2: (24, 8),   # Karo: 24 Agustus
        3: (17, 9),   # Katiga: 17 September
        4: (12, 10),  # Kapat: 12 Oktober
        5: (8, 11),   # Kalima: 8 November
        6: (21, 12),  # Kanem: 21 Desember
        7: (2, 2),    # Kapitu: 2 Februari
        8: (29 if is_kabisat else 28, 2), # Kawolu
        9: (25, 3),   # Kasanga: 25 Maret
        10: (18, 4),  # Kasepuluh: 18 April
        11: (11, 5),  # Dhesta: 11 Mei
        12: (21, 6)   # Sada: 21 Juni
    }
    
    # Periode Belahan Tahun Pertama (22 Juni - 31 Desember)
    if (bulan == 6 and tanggal >= 22) or bulan > 6:
        for i in range(1, 7):
            if tanggal <= batas[i][0] and bulan <= batas[i][1]:
                return i
            elif bulan < batas[i][1]:
                return i
        return 6 # Fallback ke Kanem jika melewati batas iterasi
    
    # Periode Belahan Tahun Kedua (1 Januari - 21 Juni)
    if (bulan == 6 and tanggal <= 21) or bulan < 6:
        for i in range(7, 13):
            if tanggal <= batas[i][0] and bulan <= batas[i][1]:
                return i
            elif bulan < batas[i][1]:
                return i
        return 12 # Fallback ke Sada jika melewati batas iterasi
```

---

## BAGIAN 2: JSON KAMUS DATA PRANATA MANGSA (`pranata-mangsa.json`)

Struktur data di bawah ini menggabungkan arketipe modern dan narasi empatik dari kedua riset, serta melengkapinya dengan array `saran_aktivitas` untuk memperkaya visualisasi dan interaksi aplikasi Aestral.

```json
[
  {
    "id": 1,
    "nama_mangsa": "Kasa",
    "nama_lain": "Kartika",
    "tanggal_siklus": "22 Juni - 1 Agustus",
    "candra_mangsa": "Sotya murca saking embanan",
    "arketipe_modern": "Sang Pembersih Lahan (Ego-Death & Decluttering)",
    "karakter_energi": "Energi pembersihan dan persiapan. Saatnya membersihkan sisa-sisa masa lalu dan menyiapkan fondasi untuk babak baru dalam hidup.",
    "ramalan_karier": "Seperti petani yang membakar sisa batang padi, ini saatnya membersihkan meja kerja dan menyelesaikan urusan lama. Jangan memulai proyek besar dulu—fokus pada perencanaan dan persiapan. Gunakan energi ini untuk declutter digital dan fisik agar produktivitasmu melesat di kemudian hari.",
    "ramalan_asmara": "Daun-daun berguguran mengajarkan bahwa melepas adalah bagian dari proses. Jika ada hubungan yang sudah tidak sehat, ini waktu yang tepat untuk mengakhiri dengan damai. Bagi yang berkomitmen, bersihkan hati dari ekspektasi berlebihan dan terima pasangan apa adanya.",
    "pesan_kesadaran": "Kadang kita harus merelakan yang lama agar ruang untuk yang baru terbuka.",
    "saran_aktivitas": [
      "Lakukan audit pengeluaran bulanan dan hapus langganan tidak terpakai",
      "Bersihkan lemari pakaian atau meja kerja Anda",
      "Batasi konsumsi media sosial untuk menjernihkan pikiran"
    ]
  },
  {
    "id": 2,
    "nama_mangsa": "Karo",
    "nama_lain": "Pusa",
    "tanggal_siklus": "2 Agustus - 24 Agustus",
    "candra_mangsa": "Bantala rengka",
    "arketipe_modern": "Sang Penguji Ketahanan (Vulnerability & Resilience)",
    "karakter_energi": "Energi ujian dan ketahanan di masa paceklik. Saat sumber daya terbatas, kreativitas dan kesabaranmu diuji.",
    "ramalan_karier": "Ini adalah masa paceklik karier—proyek mungkin berjalan lambat, rezeki terasa seret. Jangan panik. Ini justru saat yang tepat untuk berinovasi dengan sumber daya yang ada. Cari cara hemat dan efisien untuk tetap produktif. Ingat, tanaman palawija tetap tumbuh meski tanah retak.",
    "ramalan_asmara": "Hubungan diuji oleh keterbatasan—baik waktu, perhatian, maupun materi. Jangan biarkan stres pekerjaan merusak kehangatan. Komunikasi sederhana tapi rutin lebih berharga daripada kencan mewah. Yang bertahan di masa sulit akan tumbuh lebih kuat.",
    "pesan_kesadaran": "Kekuatan sejati terlihat saat kita menghadapi keterbatasan, bukan saat segala sesuatu berlimpah.",
    "saran_aktivitas": [
      "Jurnal harian untuk melacak kecemasan dan hal-hal yang Anda syukuri",
      "Fokus pada self-healing, minum cukup air, dan olahraga ringan",
      "Evaluasi rencana investasi masa depan Anda"
    ]
  },
  {
    "id": 3,
    "nama_mangsa": "Katiga",
    "nama_lain": "Mangasri",
    "tanggal_siklus": "25 Agustus - 17 September",
    "candra_mangsa": "Suta manut ing bapa",
    "arketipe_modern": "Sang Pemanen Awal (Mentorship & Disiplin)",
    "karakter_energi": "Energi kepatuhan pada proses dan disiplin. Hasil mulai terlihat dari kerja keras sebelumnya.",
    "ramalan_karier": "Hasil kerja kerasmu mulai berbuah—mungkin dalam bentuk pengakuan, promosi kecil, atau proyek yang selesai tepat waktu. Ini saatnya memanen apa yang sudah ditanam, sekecil apapun. Jangan tergoda untuk mengambil jalan pintas; tetap patuh pada standar dan etos kerjamu.",
    "ramalan_asmara": "Seperti palawija yang mulai bisa dipanen, hubungan yang dibangun dengan sabar mulai menunjukkan hasil. Pasangan mungkin mulai lebih terbuka atau menunjukkan apresiasi. Tetaplah konsisten—jangan berubah drastis hanya karena situasi membaik.",
    "pesan_kesadaran": "Disiplin dan konsistensi adalah orang tua dari keberhasilan.",
    "saran_aktivitas": [
      "Hubungi mentor atau rekan senior untuk sesi bincang karier kasual",
      "Beli buku atau langganan kursus edukatif baru",
      "Buat jadwal rutinitas harian yang lebih disiplin"
    ]
  },
  {
    "id": 4,
    "nama_mangsa": "Kapat",
    "nama_lain": "Sitra",
    "tanggal_siklus": "18 September - 12 Oktober",
    "candra_mangsa": "Waspa kumembeng jroning kalbu",
    "arketipe_modern": "Sang Penahan Kesabaran (Emotional Healing & Transisi)",
    "karakter_energi": "Energi transisi dan kesabaran. Perubahan besar sedang terjadi di balik layar—bersiaplah.",
    "ramalan_karier": "Kesabaranmu diuji habis-habisan. Ini masa transisi—kemarau akan berakhir, tapi hujan belum tiba. Jangan mengambil keputusan besar atau berganti karier secara impulsif. Tahan diri, persiapkan bibit ide untuk musim berikutnya. Air mata kesabaran akan berbuah manis.",
    "ramalan_asmara": "Seperti petani yang menyiapkan bibit di tengah kekeringan, ini saatnya mempersiapkan hati untuk fase baru hubungan. Mungkin ada kerinduan atau ketegangan yang tertahan—ungkapkan dengan bijak, bukan dengan ledakan emosi. Kesabaran adalah bahasa cinta yang paling dewasa.",
    "pesan_kesadaran": "Air mata yang tertahan hari ini akan menjadi hujan yang menyuburkan esok.",
    "saran_aktivitas": [
      "Lakukan aktivitas seni atau kreatif tanpa takut dinilai orang lain",
      "Habiskan waktu di alam terbuka atau taman kota di pagi hari",
      "Latih pernapasan (mindful breathing) untuk melepas stres terpendam"
    ]
  },
  {
    "id": 5,
    "nama_mangsa": "Kalima",
    "nama_lain": "Manggakala",
    "tanggal_siklus": "13 Oktober - 8 November",
    "candra_mangsa": "Pancuran emas sumawur ing jagat",
    "arketipe_modern": "Sang Pembuka Jalan (Abundance & Peluang)",
    "karakter_energi": "Energi pembaruan dan harapan. Hujan pertama turun—ide dan peluang baru mulai muncul.",
    "ramalan_karier": "Hujan ide segar mulai turun! Proyek baru, koneksi menarik, atau terobosan kreatif datang menghampiri. Sambut dengan tangan terbuka. Ini waktu yang tepat untuk memulai inisiatif baru atau mengajukan proposal yang selama ini kamu pendam. Energi positif ini membawa berkah.",
    "ramalan_asmara": "Cinta baru berpotensi muncul—atau percikan lama bisa menyala kembali. Bagi yang berkomitmen, ini saat yang tepat untuk 'menyirami' hubungan dengan perhatian dan kejutan manis. Bagi yang single, buka hatimu; hujan pertama membawa harapan.",
    "pesan_kesadaran": "Setiap awal yang baik dimulai dengan setetes keberanian.",
    "saran_aktivitas": [
      "Ajukan proposal proyek atau kirim aplikasi kerja ke tempat impian Anda",
      "Jadwalkan kencan seru di luar ruangan (seperti piknik atau jalan-jalan santai)",
      "Lakukan donasi atau kebaikan kecil untuk mengalirkan energi keberkahan"
    ]
  },
  {
    "id": 6,
    "nama_mangsa": "Kanem",
    "nama_lain": "Naya",
    "tanggal_siklus": "9 November - 21 Desember",
    "candra_mangsa": "Rasa mulya kasucen",
    "arketipe_modern": "Sang Pekerja Gembira (Maturitas & Flow)",
    "karakter_energi": "Energi kelimpahan dan semangat produktif. Bekerja keras terasa ringan karena tujuan jelas.",
    "ramalan_karier": "Ini adalah musim 'flow'—bekerja terasa menyenangkan dan hasil melimpah. Curah hujan ide dan produktivitas tinggi. Manfaatkan momentum ini untuk menuntaskan target besar sebelum akhir tahun. Keuangan pun mulai membaik. Nikmati prosesnya, karena kerja keras yang dilakukan dengan gembira akan berbuah manis.",
    "ramalan_asmara": "Cinta mengalir deras dan hangat. Hubungan terasa lebih romantis dan penuh berkah. Rencanakan quality time atau liburan singkat. Bagi yang single, energi positifmu sangat menarik—jangan takut untuk mengambil inisiatif.",
    "pesan_kesadaran": "Bekerja dengan hati adalah bentuk ibadah pada diri sendiri.",
    "saran_aktivitas": [
      "Adakan makan malam kecil bersama orang terdekat untuk merayakan kesuksesan bersama",
      "Tulis rangkuman refleksi diri mengenai pencapaian setahun terakhir",
      "Manjakan diri Anda dengan sesi spa atau pijat relaksasi"
    ]
  },
  {
    "id": 7,
    "nama_mangsa": "Kapitu",
    "nama_lain": "Palguna",
    "tanggal_siklus": "22 Desember - 2 Februari",
    "candra_mangsa": "Wisa kentar ing maruta",
    "arketipe_modern": "Sang Penjaga Kesehatan Mental (Cozy Cocooning & Boundaries)",
    "karakter_energi": "Energi yang intens dan penuh tantangan emosional. Waspada terhadap 'racun' pikiran negatif dan stres.",
    "ramalan_karier": "Musim hujan deras dalam karier—beban kerja menumpuk, deadline berdesakan, dan tekanan dari atasan meningkat. Jaga kesehatan mentalmu dengan prioritisasi dan delegasi. Jangan biarkan 'racun' stres meracuni produktivitasmu. Istirahat cukup adalah investasi, bukan kemalasan.",
    "ramalan_asmara": "Hubungan bisa terasa 'banjir'—emosi meluap, konflik kecil membesar. Ingat, ini musim ujian. Jaga komunikasi tetap jernih dan hindari kata-kata yang menyakitkan. Beri ruang untuk diri sendiri dan pasangan; kadang diam lebih baik dari pada bertengkar.",
    "pesan_kesadaran": "Jagalah pikiranmu seperti menjaga sawah dari banjir—bendung yang negatif, salurkan yang positif.",
    "saran_aktivitas": [
      "Matikan notifikasi pekerjaan setelah jam kantor untuk menjaga kesehatan mental",
      "Buat minuman hangat dan nikmati waktu santai membaca buku di rumah",
      "Lakukan meditasi grounding untuk meredakan kecemasan makro"
    ]
  },
  {
    "id": 8,
    "nama_mangsa": "Kawolu",
    "nama_lain": "Wisaka",
    "tanggal_siklus": "3 Februari - 28 Februari",
    "candra_mangsa": "Anjrah jroning kayun",
    "arketipe_modern": "Sang Penyebar Kebaikan (Passion & Kolaborasi)",
    "karakter_energi": "Energi kebahagiaan yang menyebar luas. Koneksi sosial dan kolaborasi membawa berkah.",
    "ramalan_karier": "Seperti padi yang mulai berbunga, kerja tim dan kolaborasi sedang di puncak kejayaannya. Bagikan ide dan apresiasi pada rekan kerja; energi positifmu akan menyebar dan kembali padamu. Ini waktu yang tepat untuk networking dan membangun hubungan profesional yang langgeng.",
    "ramalan_asmara": "Cinta menyebar merata—hubungan terasa hangat dan penuh pengertian. Bagi yang berkomitmen, ini saatnya berbagi mimpi dan rencana masa depan. Bagi yang single, keterbukaan hatimu akan menarik orang-orang baik ke dalam hidupmu.",
    "pesan_kesadaran": "Kebahagiaan sejati adalah kebahagiaan yang dibagikan.",
    "saran_aktivitas": [
      "Hadiri acara komunitas, seminar, atau pertemuan sosial baru",
      "Ubah penampilan atau gaya berpakaian Anda untuk meningkatkan kepercayaan diri",
      "Mulailah mengerjakan proyek hobi yang paling membuat Anda bersemangat"
    ]
  },
  {
    "id": 9,
    "nama_mangsa": "Kasanga",
    "nama_lain": "Jita",
    "tanggal_siklus": "1 Maret - 25 Maret",
    "candra_mangsa": "Wedharing wacana mulya",
    "arketipe_modern": "Sang Pembawa Kabar Baik (Ekspresi Diri & Sharing)",
    "karakter_energi": "Energi kegembiraan dan pengakuan. Hasil kerja keras mulai terlihat dan diapresiasi.",
    "ramalan_karier": "Kabar baik datang bertubi-tubi! Pengakuan atas kerja kerasmu, mungkin berupa pujian atasan, kenaikan gaji, atau tawaran proyek menarik. Ini saatnya merayakan pencapaian—tapi jangan terlena. Gunakan momentum ini untuk melompat ke level berikutnya.",
    "ramalan_asmara": "Seperti padi yang siap dipanen, hubunganmu sedang di masa terbaik. Jika ada perasaan yang selama ini terpendam, ini saat yang tepat untuk mengungkapkannya. Bagi yang single, kabar baik dalam karir juga bisa menarik perhatian orang baru.",
    "pesan_kesadaran": "Rayakan setiap kemenangan kecil—itu adalah bahan bakar untuk perjalanan panjang.",
    "saran_aktivitas": [
      "Tulis jurnal reflektif atau bagikan tulisan edukasi di LinkedIn/blog",
      "Luangkan waktu 1 jam khusus untuk mendengarkan curhat pasangan secara aktif",
      "Rapikan catatan-catatan ide kerja Anda agar lebih terstruktur"
    ]
  },
  {
    "id": 10,
    "nama_mangsa": "Kasepuluh",
    "nama_lain": "Srawana",
    "tanggal_siklus": "26 Maret - 18 April",
    "candra_mangsa": "Gedhong mineb jroning kalbu",
    "arketipe_modern": "Sang Penjaga Hasil (Financial & Security)",
    "karakter_energi": "Energi perlindungan dan kewaspadaan. Jaga apa yang sudah diraih dari ancaman eksternal.",
    "ramalan_karier": "Musim panen besar—tapi waspadai 'burung pipit' yang ingin mengambil hasilmu. Ini saatnya melindungi karya dan ide dari plagiarisme atau persaingan tidak sehat. Perkuat portofoliomu dan dokumentasikan pencapaian. Jangan terlalu percaya pada orang baru.",
    "ramalan_asmara": "Hubungan yang sudah baik perlu dijaga dari gangguan eksternal—gosip, campur tangan pihak ketiga, atau kesalahpahaman. Perkuat benteng kepercayaan dengan pasangan. Bagi yang single, fokus pada diri sendiri; cinta sejati tidak perlu dikejar.",
    "pesan_kesadaran": "Menjaga apa yang sudah dimiliki adalah bentuk kebijaksanaan.",
    "saran_aktivitas": [
      "Hitung kekayaan bersih (net worth) Anda dan evaluasi portofolio investasi",
      "Beli hadiah kecil berkualitas untuk diri sendiri dan orang yang membantu Anda",
      "Set alokasi tabungan otomatis untuk dana darurat Anda"
    ]
  },
  {
    "id": 11,
    "nama_mangsa": "Dhesta",
    "nama_lain": "Pandrawana",
    "tanggal_siklus": "19 April - 11 Mei",
    "candra_mangsa": "Sotya sinar angrengga wicara",
    "arketipe_modern": "Sang Pengasuh (Apresiasi & Perlambatan)",
    "karakter_energi": "Energi kelembutan dan pengasuhan. Saatnya memberi perhatian pada hal-hal kecil dan orang-orang terdekat.",
    "ramalan_karier": "Seperti burung yang menyuapi anaknya, ini saatnya memberi 'makan' pada proyek-proyek yang kamu asuh sejak awal. Detail kecil yang selama ini terabaikan perlu mendapat perhatian. Jangan hanya fokus pada hasil besar—rawat prosesnya dengan sabar dan teliti.",
    "ramalan_asmara": "Kelembutan dan perhatian adalah bahasamu minggu ini. Pasangan atau orang terdekat membutuhkan kehadiran emosionalmu. Bagi yang single, energi pengasuhan ini bisa kamu salurkan pada diri sendiri—rawat tubuh dan pikiranmu seperti kamu merawat orang yang kamu cintai.",
    "pesan_kesadaran": "Memberi perhatian pada hal kecil adalah bentuk cinta paling sederhana dan paling dalam.",
    "saran_aktivitas": [
      "Kirim pesan apresiasi atau hadiah kecil ke teman yang selalu mendukung Anda",
      "Latih rasa syukur harian dengan mencatat 3 hal baik setiap malam sebelum tidur",
      "Lakukan digital detox di akhir pekan bersama keluarga atau pasangan"
    ]
  },
  {
    "id": 12,
    "nama_mangsa": "Sada",
    "nama_lain": "Asuji",
    "tanggal_siklus": "12 Mei - 21 Juni",
    "candra_mangsa": "Tirta sah saking sasana",
    "arketipe_modern": "Sang Pengumpul Hasil (Detachment & Refleksi)",
    "karakter_energi": "Energi penyelesaian dan refleksi. Tutup siklus dengan rasa syukur dan persiapan untuk awal baru.",
    "ramalan_karier": "Siklus tahunan akan segera berakhir—ini saatnya menyelesaikan semua pekerjaan yang tertunda. Rapikan arsip, tutup laporan, dan evaluasi pencapaian setahun terakhir. Jangan memulai proyek baru yang besar; fokus pada menyelesaikan dengan rapi. Persiapan yang baik akan membuat awal siklus baru lebih lancar.",
    "ramalan_asmara": "Musim dingin dalam hubungan—bukan berarti membeku, tapi saatnya refleksi dan kehangatan sederhana. Evaluasi perjalanan hubungan setahun terakhir. Apa yang sudah baik? Apa yang perlu diperbaiki? Bagi yang single, refleksi diri akan membawamu pada pemahaman tentang apa yang benar-benar kamu butuhkan.",
    "pesan_kesadaran": "Setiap akhir adalah awal yang baru. Tutup dengan syukur, buka dengan harapan.",
    "saran_aktivitas": [
      "Lakukan meditasi pelepasan emosi untuk membuang dendam atau rasa bersalah",
      "Tulis rencana resolusi besar untuk siklus Pranata Mangsa berikutnya",
      "Nikmati keheningan malam hari tanpa distraksi layar ponsel"
    ]
  }
]
```
