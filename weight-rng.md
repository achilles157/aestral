# Context: Implementasi "Weighted RNG Tarot" Berbasis Elemen Ba Zi/Weton

## Objektif
Buatkan sebuah fungsi TypeScript untuk Cloudflare Workers yang bertugas menarik satu kartu Tarot harian dari pool 78 kartu. Penarikan ini BUKAN murni acak (Pure RNG), melainkan menggunakan sistem "Weighted Random Selection" (RNG Berbobot) yang disinkronkan dengan kondisi elemen astrologi pengguna hari ini.

## Aturan Pemetaan Elemen (Tarot to Ba Zi/Weton)
Anda harus memetakan 4 Suit Tarot ke dalam elemen Wu Xing (Ba Zi):
- Suit of Cups (Piala) = Elemen Air (Water)
- Suit of Wands (Tongkat) = Elemen Api (Fire)
- Suit of Pentacles (Koin) = Elemen Tanah (Earth)
- Suit of Swords (Pedang) = Elemen Logam (Metal)
- Major Arcana = Netral (Elemen Kayu/Wood atau Spirit, bobot standar).

## Logika Pembobotan (ReRanker Logic)
1. Inisialisasi pool 78 kartu Tarot, berikan nilai awal `weight: 1.0` untuk setiap kartu.
2. Fungsi ini menerima parameter dari Frontend berupa: `user_dominant_element` (elemen yang sedang kuat hari ini) dan `user_deficient_element` (elemen yang sedang lemah/dibutuhkan hari ini).
3. Terapkan logika "Kompensasi" dan "Resonansi":
   - Jika sebuah kartu memiliki elemen yang sama dengan `user_deficient_element`, tambahkan bobotnya sebesar `+0.8` (Kompensasi: memprioritaskan elemen yang hilang untuk menyeimbangkan nasib).
   - Jika sebuah kartu memiliki elemen yang sama dengan `user_dominant_element`, tambahkan bobotnya sebesar `+0.3` (Resonansi: memperkuat karakter bawaan).
4. Buat fungsi `weightedRandomChoice(pool)` yang menjumlahkan total bobot (cumulative weights), menghasilkan angka acak antara 0 hingga total bobot, dan mengembalikan kartu yang terpilih.

## Aturan Kode (Constraints)
- Gunakan TypeScript yang strongly-typed (buatkan `interface TarotCard` dan `interface DrawParams`).
- Algoritma harus berjalan dengan kompleksitas waktu O(N) agar zero-latency di jaringan Edge Cloudflare.
- Kembalikan response dalam bentuk JSON yang berisi data kartu terpilih beserta alasan metadata-nya (misal: `is_weighted_draw: true`, `dominant_element_applied: "Fire"`).