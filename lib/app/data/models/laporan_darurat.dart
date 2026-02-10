class LaporanDarurat {
  String idLaporan;
  String tipeKejadian;
  String statusLaporan; // Contoh: "AKTIF", "DIBATALKAN", "SELESAI"
  DateTime waktu;
  String lokasiGPS;
  String modeAlarm; // Contoh: "SENYAP" atau "ALARM"
  int jumlahHelper;

  LaporanDarurat({
    required this.idLaporan,
    required this.tipeKejadian,
    required this.statusLaporan,
    required this.waktu,
    required this.lokasiGPS,
    required this.modeAlarm,
    this.jumlahHelper = 0,
  });

  // Setter methods sesuai Sequence Diagram (Halaman 28)
  // Agar controller bisa mengubah nilai properti menggunakan nama fungsi yang ada di desain
  void setModeAlarm(String mode) => this.modeAlarm = mode;
  void setLokasiGPS(String lokasi) => this.lokasiGPS = lokasi;
  void setWaktu(DateTime now) => this.waktu = now;
  void setStatusLaporan(String status) => this.statusLaporan = status;
  void setTipeKejadian(String tipe) => this.tipeKejadian = tipe;
  void setJumlahHelper(int jumlah) => this.jumlahHelper = jumlah;
}
