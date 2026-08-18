class ProfileInfo {
  final String? name;
  final String? phone;
  final String? photo;

  const ProfileInfo({this.name, this.phone, this.photo});

  ProfileInfo copyWith({String? name, String? phone, String? photo}) {
    return ProfileInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (photo != null) 'photo': photo,
      };

  factory ProfileInfo.fromJson(Map<String, dynamic> json) => ProfileInfo(
        name: json['name'],
        phone: json['phone'],
        photo: json['photo'],
      );
}