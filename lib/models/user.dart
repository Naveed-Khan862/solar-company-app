enum UserRole { superAdmin, subAdmin, user }

class UserModel {
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  const UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  bool get isAdmin => role == UserRole.superAdmin || role == UserRole.subAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isSubAdmin => role == UserRole.subAdmin;

  String get roleLabel {
    switch (role) {
      case UserRole.superAdmin:
        return 'CEO';
      case UserRole.subAdmin:
        return 'Sub Admin';
      case UserRole.user:
        return 'User';
    }
  }
}
