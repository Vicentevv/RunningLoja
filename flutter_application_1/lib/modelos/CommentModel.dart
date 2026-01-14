class CommentModel {
  String id;
  String userId;
  String userName;
  String text;
  DateTime createdAt;

  bool isVerified;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "userName": userName,
      "text": text,
      "createdAt": createdAt.toIso8601String(),
      "isVerified": isVerified,
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json["id"],
      userId: json["userId"],
      userName: json["userName"],
      text: json["text"],
      createdAt: DateTime.parse(json["createdAt"]),
      isVerified: json["isVerified"] ?? false,
    );
  }
}
