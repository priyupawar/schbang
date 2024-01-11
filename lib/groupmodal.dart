// ignore_for_file: non_constant_identifier_names

class Group {
  final String name;
  final String description;
  final String profile;
  final String id;
  final String type;
  final String created_at;
  final List<dynamic> members;

  Group(
      {required this.name,
      required this.profile,
      required this.description,
      required this.id,
      required this.members,
      required this.type,
      required this.created_at});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
        name: json['name'],
        profile: json['profile'],
        description: json['description'],
        id: json['id'],
        members: json['members'],
        type: json['type'],
        created_at: json['create_at']);
  }
  factory Group.fromMap(Map<String, dynamic> data) {
    return Group(
        name: data['groupname'].toString(),
        profile: data['profile'].toString(),
        description: data['groupdescription'].toString(),
        id: data['id'].toString(),
        members: data['members'],
        type: data['type'],
        created_at: data['create_at']);
  }
}
