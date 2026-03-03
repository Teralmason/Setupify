class SetupModel {
  final String id;
  final String title;
  final String? description;
  final List<String> images;
  final Map<String, String> specs; // RAM, GPU vb.
  final List<String>? links;
  int likes;
  final String userName;
  bool isFavorite;

  SetupModel({
    required this.id,
    required this.title,
    this.description,
    required this.images,
    required this.specs,
    this.links,
    this.likes = 0,
    required this.userName,
    this.isFavorite = false,
  });
}
