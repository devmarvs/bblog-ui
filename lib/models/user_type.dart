class UserType {
  final int id;
  final String description;

  const UserType({required this.id, required this.description});

  factory UserType.fromJson(Map<String, dynamic> json) {
    final rawId = json['userTypeId'] ??
        json['user_type_id'] ??
        json['userTypeID'] ??
        json['id'];
    final rawDescription = json['description'] ?? json['name'] ?? '';
    return UserType(
      id: (rawId is int) ? rawId : int.tryParse(rawId.toString()) ?? 0,
      description: rawDescription.toString(),
    );
  }
}
