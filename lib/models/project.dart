class Project {
  final int? id;
  final String name;
  final String projectCode;
  final String projectType;
  final String status;
  final String statusColorHex;
  final String statusBgColorHex;
  final String location;
  final String pafta;
  final String parsel;
  final int areaSqMeters;
  final int totalIndependentSections;
  final int unitCount;
  final int shopCount;
  final double estimatedTotalCost;
  final double estimatedTotalRevenue;
  final String? imagePath;
  final String startDate;
  final String endDate;
  final String description;

  Project({
    this.id,
    required this.name,
    this.projectCode = '',
    this.projectType = 'Konut',
    required this.status,
    required this.statusColorHex,
    required this.statusBgColorHex,
    this.location = '',
    this.pafta = '',
    this.parsel = '',
    this.areaSqMeters = 0,
    this.totalIndependentSections = 0,
    this.unitCount = 0,
    this.shopCount = 0,
    this.estimatedTotalCost = 0.0,
    this.estimatedTotalRevenue = 0.0,
    this.imagePath,
    this.startDate = '',
    this.endDate = '',
    this.description = '',
  });

  /// Optimistic eklemede geçici id atamak için (arkaplan senkron gerçek id ile değiştirir).
  Project withId(int? newId) => Project(
        id: newId,
        name: name,
        projectCode: projectCode,
        projectType: projectType,
        status: status,
        statusColorHex: statusColorHex,
        statusBgColorHex: statusBgColorHex,
        location: location,
        pafta: pafta,
        parsel: parsel,
        areaSqMeters: areaSqMeters,
        totalIndependentSections: totalIndependentSections,
        unitCount: unitCount,
        shopCount: shopCount,
        estimatedTotalCost: estimatedTotalCost,
        estimatedTotalRevenue: estimatedTotalRevenue,
        imagePath: imagePath,
        startDate: startDate,
        endDate: endDate,
        description: description,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'project_code': projectCode,
      'project_type': projectType,
      'status': status,
      'status_color_hex': statusColorHex,
      'status_bg_color_hex': statusBgColorHex,
      'location': location,
      'pafta': pafta,
      'parsel': parsel,
      'area_sq_meters': areaSqMeters,
      'total_independent_sections': totalIndependentSections,
      'unit_count': unitCount,
      'shop_count': shopCount,
      'estimated_total_cost': estimatedTotalCost,
      'estimated_total_revenue': estimatedTotalRevenue,
      'image_path': imagePath,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'] ?? '',
      projectCode: map['project_code'] ?? '',
      projectType: map['project_type'] ?? 'Konut',
      status: map['status'] ?? '',
      statusColorHex: map['status_color_hex'] ?? '',
      statusBgColorHex: map['status_bg_color_hex'] ?? '',
      location: map['location'] ?? '',
      pafta: map['pafta'] ?? '',
      parsel: map['parsel'] ?? '',
      areaSqMeters: map['area_sq_meters'] ?? 0,
      totalIndependentSections: map['total_independent_sections'] ?? 0,
      unitCount: map['unit_count'] ?? 0,
      shopCount: map['shop_count'] ?? 0,
      estimatedTotalCost: map['estimated_total_cost']?.toDouble() ?? 0.0,
      estimatedTotalRevenue: map['estimated_total_revenue']?.toDouble() ?? 0.0,
      imagePath: map['image_path'],
      startDate: map['start_date'] ?? '',
      endDate: map['end_date'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
