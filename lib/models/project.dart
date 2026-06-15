class Project {
  final int? id;
  final String name;
  final String status;
  final String statusColorHex;
  final String statusBgColorHex;
  final String location;
  final int areaSqMeters;
  final int unitCount;
  final int shopCount;
  final double estimatedTotalCost;
  final double estimatedTotalRevenue;
  final String? imagePath;

  Project({
    this.id,
    required this.name,
    required this.status,
    required this.statusColorHex,
    required this.statusBgColorHex,
    this.location = '',
    this.areaSqMeters = 0,
    this.unitCount = 0,
    this.shopCount = 0,
    this.estimatedTotalCost = 0.0,
    this.estimatedTotalRevenue = 0.0,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'statusColorHex': statusColorHex,
      'statusBgColorHex': statusBgColorHex,
      'location': location,
      'areaSqMeters': areaSqMeters,
      'unitCount': unitCount,
      'shopCount': shopCount,
      'estimatedTotalCost': estimatedTotalCost,
      'estimatedTotalRevenue': estimatedTotalRevenue,
      'imagePath': imagePath,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      status: map['status'],
      statusColorHex: map['statusColorHex'],
      statusBgColorHex: map['statusBgColorHex'],
      location: map['location'] ?? '',
      areaSqMeters: map['areaSqMeters'] ?? 0,
      unitCount: map['unitCount'] ?? 0,
      shopCount: map['shopCount'] ?? 0,
      estimatedTotalCost: map['estimatedTotalCost']?.toDouble() ?? 0.0,
      estimatedTotalRevenue: map['estimatedTotalRevenue']?.toDouble() ?? 0.0,
      imagePath: map['imagePath'],
    );
  }
}
