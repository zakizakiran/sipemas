class LaporanDarurat {
  String idLaporan;
  String pembuatId; // <-- TAMBAHKAN INI (ID User Pembuat)
  String tipeKejadian;
  String statusLaporan;
  DateTime waktu;
  String lokasiGPS;
  String modeAlarm;
  int jumlahHelper;

  LaporanDarurat({
    required this.idLaporan,
    required this.pembuatId, // <-- TAMBAHKAN DI CONSTRUCTOR
    required this.tipeKejadian,
    required this.statusLaporan,
    required this.waktu,
    required this.lokasiGPS,
    required this.modeAlarm,
    this.jumlahHelper = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_laporan': idLaporan,
      'pembuat_id': pembuatId, // <-- MASUKKAN KE JSON
      'tipe_kejadian': tipeKejadian,
      'status_laporan': statusLaporan,
      'waktu': waktu.toIso8601String(),
      'lokasi_gps': lokasiGPS,
      'mode_alarm': modeAlarm,
      'jumlah_helper': jumlahHelper,
    };
  }

  factory LaporanDarurat.fromJson(Map<String, dynamic> json) {
    return LaporanDarurat(
      idLaporan: json['id_laporan'] ?? '',
      pembuatId: json['pembuat_id'] ?? '', // <-- AMBIL DARI JSON
      tipeKejadian: json['tipe_kejadian'] ?? 'SOS',
      statusLaporan: json['status_laporan'] ?? 'AKTIF',
      waktu: DateTime.parse(json['waktu']),
      lokasiGPS: json['lokasi_gps'] ?? '',
      modeAlarm: json['mode_alarm'] ?? 'ALARM',
      jumlahHelper: json['jumlah_helper'] ?? 0,
    );
  }

  // Setter methods (tetap pertahankan yang lama)
  void setModeAlarm(String mode) => this.modeAlarm = mode;
  void setLokasiGPS(String lokasi) => this.lokasiGPS = lokasi;
  void setWaktu(DateTime now) => this.waktu = now;
  void setStatusLaporan(String status) => this.statusLaporan = status;
  void setTipeKejadian(String tipe) => this.tipeKejadian = tipe;
  void setJumlahHelper(int jumlah) => this.jumlahHelper = jumlah;
}
