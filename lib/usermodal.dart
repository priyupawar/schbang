// ignore_for_file: non_constant_identifier_names

class User {
  String name;
  String profile;
  String id;
  String type;
  String created_at;

  User(
      {required this.name,
      required this.profile,
      required this.id,
      required this.type,
      required this.created_at});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        name: json['name'],
        profile: json['profile'],
        id: json['id'],
        type: json['type'],
        created_at: json['created_at']);
  }
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
        name: data['name'].toString(),
        profile: data['profile'].toString(),
        id: data['id'].toString(),
        type: data['type'].toString(),
        created_at: data['created_at'].toString());
  }
}
