/// Mirrors backend `roles` table: customer / delivery / admin (admin uses the web app).
enum UserRole { customer, delivery }

extension UserRoleJson on UserRole {
  String get value => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.customer,
    );
  }
}
