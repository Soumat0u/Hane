class CompanyProfile {
  final int? id;
  final String companyName;
  final String taxOffice;
  final String taxNumber;
  final String commercialRegistry;
  final String mersisNo;
  final String addressTitle;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String country;
  final String phone1;
  final String phone2;
  final String email;
  final String website;

  CompanyProfile({
    this.id,
    required this.companyName,
    required this.taxOffice,
    required this.taxNumber,
    required this.commercialRegistry,
    required this.mersisNo,
    required this.addressTitle,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.country,
    required this.phone1,
    required this.phone2,
    required this.email,
    required this.website,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'tax_office': taxOffice,
      'tax_number': taxNumber,
      'commercial_registry': commercialRegistry,
      'mersis_no': mersisNo,
      'address_title': addressTitle,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'country': country,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'website': website,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'],
      companyName: map['company_name'] ?? '',
      taxOffice: map['tax_office'] ?? '',
      taxNumber: map['tax_number'] ?? '',
      commercialRegistry: map['commercial_registry'] ?? '',
      mersisNo: map['mersis_no'] ?? '',
      addressTitle: map['address_title'] ?? '',
      addressLine1: map['address_line1'] ?? '',
      addressLine2: map['address_line2'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      phone1: map['phone1'] ?? '',
      phone2: map['phone2'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
    );
  }
}
