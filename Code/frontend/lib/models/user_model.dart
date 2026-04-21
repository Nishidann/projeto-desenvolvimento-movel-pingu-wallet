class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  // Transforma o objeto em um Mapa (JSON) para enviar ao Backend
  Map<String, dynamic> toJson() {
    return {
      'googleId': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  // Cria um objeto UserModel a partir de um mapa (útil se o backend devolver o usuário)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['googleId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}
