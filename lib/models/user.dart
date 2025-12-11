class UserModel {
  final String id;
  final String pseudo;
  final String profilePicture;
  final String bio;
  final List<String> abonnements;
  final List<String> abonnes;

  UserModel({
    required this.id,
    required this.pseudo,
    required this.profilePicture,
    required this.bio,
    required this.abonnements,
    required this.abonnes,
  });

  // Convertir Firestore en objet Dart
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      pseudo: data['pseudo'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      bio: data['bio'] ?? '',
      abonnements: List<String>.from(data['abonnements'] ?? []),
      abonnes: List<String>.from(data['abonnes'] ?? []),
    );
  }

  // Convertir un objet Dart en Firestore
  Map<String, dynamic> toMap() {
    return {
      'pseudo': pseudo,
      'profilePicture': profilePicture,
      'bio': bio,
      'abonnements': abonnements,
      'abonnes': abonnes,
    };
  }
}
