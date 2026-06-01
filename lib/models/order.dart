class Order {

  final int id;
  final String resi;
  final String namaPabrik;
  final String alamatAsal;
  final String alamatTujuan;
  final String alamatAsalClean;
  final String alamatTujuanClean;
  final String? alamatAsalCoordinate;
  final String? alamatTujuanCoordinate;
  final String jenisBarang;
  final int berat;
  final String status;
  final String statusPengiriman;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.resi,
    required this.namaPabrik,
    required this.alamatAsal,
    required this.alamatTujuan,
    required this.alamatAsalClean,
    required this.alamatTujuanClean,
    this.alamatAsalCoordinate,
    this.alamatTujuanCoordinate,
    required this.jenisBarang,
    required this.berat,
    required this.status,
    required this.statusPengiriman,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json["id"],
      resi: json["resi"],
      namaPabrik: json["nama_pabrik"],
      alamatAsal: json["alamat_asal"] ?? "",
      alamatTujuan: json["alamat_tujuan"] ?? "",
      alamatAsalClean: json["alamat_asal_clean"] ?? json["alamat_asal"] ?? "",
      alamatTujuanClean: json["alamat_tujuan_clean"] ?? json["alamat_tujuan"] ?? "",
      alamatAsalCoordinate: json["alamat_asal_coordinate"],
      alamatTujuanCoordinate: json["alamat_tujuan_coordinate"],
      jenisBarang: json["jenis_barang"] ?? "",
      berat: json["berat"] ?? 0,
      status: json["status"] ?? "",
      statusPengiriman: json["status_pengiriman"] ?? "",
      updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : DateTime.now(),
    );
  }

}