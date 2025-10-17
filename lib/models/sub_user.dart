class SubUserModel {
  final String subUserId;
  final String userId;
  final String name;
  final String? description;

  SubUserModel({
    required this.subUserId,
    required this.userId,
    required this.name,
    this.description,
  });

  factory SubUserModel.fromJson(Map<String, dynamic> json) => SubUserModel(
    subUserId: json['subUserId'].toString(),
    userId: json['userId'].toString(),
    name: json['name'] ?? '',
    description: json['description'],
  );
}
