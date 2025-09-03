class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String? Shopname;
  final String? mobile;
  //final String? gstin;
  final String? gstNumber;
  final String? shopAddress;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.Shopname,
    this.mobile,
    //this.gstin,
    this.gstNumber,
    this.shopAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImage ?? '',
      'Shopname': Shopname ?? '',
      'mobile': mobile ?? '',
      'gst_number': gstNumber ?? '',
      'shop_address': shopAddress ?? '',
    };
  }


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
      Shopname: json['Shopname'],
      mobile: json['mobile'],
      gstNumber: json['gst_number'],
      shopAddress: json['shop_address'],
    );
  }
}