class SubUserModel {
  final String subUserId;
  final String userId;
  final String name;
  final String? description;
  final int? userTypeId;

  SubUserModel({
    required this.subUserId,
    required this.userId,
    required this.name,
    this.description,
    this.userTypeId,
  });

  factory SubUserModel.fromJson(Map<String, dynamic> json) => SubUserModel(
        subUserId: json['subUserId'].toString(),
        userId: json['userId'].toString(),
        name: json['name'] ?? '',
        description: json['description'],
        userTypeId: _parseUserTypeId(json),
      );

  static int? _parseUserTypeId(Map<String, dynamic> json) {
    final raw = json['userTypeId'] ??
        json['user_type_id'] ??
        json['userTypeID'] ??
        json['user_typeid'] ??
        json['userType'] ??
        json['typeId'] ??
        json['type_id'];
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }
}
