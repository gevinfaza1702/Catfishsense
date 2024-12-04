class UserModel {
  final String uid;
  final String email;
  final String? name; // Tambahkan name
  final String? phoneNumber; // Tambahkan phoneNumber

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.phoneNumber,
  });

  // Metode copyWith untuk mempermudah pembaruan objek UserModel
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  // Konversi dari dan ke Map agar bisa digunakan dengan Firestore
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      name: data['name'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }
}
