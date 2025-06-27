class UserProfile {
  final int id;
  final String username;
  final String email;
  final String fullname;
  final String role;
  final String status;
  final int age;
  final String dateOfBirth;
  final String profileImage;
  final bool isAdmin;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.fullname,
    required this.role,
    required this.status,
    required this.age,
    required this.dateOfBirth,
    required this.profileImage,
    required this.isAdmin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        fullname: json['fullname'],
        role: json['role'],
        status: json['status'],
        age: json['age'],
        dateOfBirth: json['dateofbirth'],
        profileImage: json['profile_image'] ?? '',
        isAdmin: json['isAdmin'] ?? false,
      );
}