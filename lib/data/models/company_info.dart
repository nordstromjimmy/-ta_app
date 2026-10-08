/// The user's company details, shown on exported PDFs.
class CompanyInfo {
  const CompanyInfo({
    this.name = '',
    this.contactPerson = '',
    this.orgNumber = '',
    this.address = '',
    this.postalCode = '',
    this.city = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.logoFileName,
  });

  final String name;
  final String contactPerson;
  final String orgNumber;
  final String address;
  final String postalCode;
  final String city;
  final String phone;
  final String email;
  final String website;

  /// File name only, stored in the app's image folder.
  final String? logoFileName;

  /// "123 45 Stockholm"
  String get postalLine =>
      [postalCode, city].where((s) => s.isNotEmpty).join(' ');

  CompanyInfo withLogo(String? fileName) => CompanyInfo(
    name: name,
    contactPerson: contactPerson,
    orgNumber: orgNumber,
    address: address,
    postalCode: postalCode,
    city: city,
    phone: phone,
    email: email,
    website: website,
    logoFileName: fileName,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'contactPerson': contactPerson,
    'orgNumber': orgNumber,
    'address': address,
    'postalCode': postalCode,
    'city': city,
    'phone': phone,
    'email': email,
    'website': website,
    'logoFileName': logoFileName,
  };

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    String read(String key) => json[key] as String? ?? '';
    return CompanyInfo(
      name: read('name'),
      contactPerson: read('contactPerson'),
      orgNumber: read('orgNumber'),
      address: read('address'),
      postalCode: read('postalCode'),
      city: read('city'),
      phone: read('phone'),
      email: read('email'),
      website: read('website'),
      logoFileName: json['logoFileName'] as String?,
    );
  }
}
