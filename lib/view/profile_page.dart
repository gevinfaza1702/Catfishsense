import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Tambahan untuk upload gambar ke Firebase Storage
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController emailController =
      TextEditingController(text: "catfishsense17@gmail.com");
  final TextEditingController nameController =
      TextEditingController(text: "Catfish");
  final TextEditingController phoneController =
      TextEditingController(text: "087824915616");

  User? user = FirebaseAuth.instance.currentUser;
  String? userId;
  File? _image; // Variable to store the selected image
  String? profileImageUrl; // Variable untuk menyimpan URL gambar dari Firebase

  @override
  void initState() {
    super.initState();
    userId = user?.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (userId != null) {
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();

      setState(() {
        emailController.text = userData.data()?['email'] ?? '';
        nameController.text = userData.data()?['namaLengkap'] ?? '';
        phoneController.text = userData.data()?['nomorHandphone'] ?? '';
        profileImageUrl = userData.data()?['profileImageUrl'];
      });
    }
  }

  Future<void> _reauthenticateUser() async {
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: 'password', // Password asli pengguna
      );

      try {
        await user!.reauthenticateWithCredential(credential);
      } catch (e) {
        print("Gagal re-authenticate: $e");
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
      await _uploadProfileImage(); // Upload gambar ke Firebase
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_image != null && userId != null) {
      try {
        // Upload gambar ke Firebase Storage
        final storageRef =
            FirebaseStorage.instance.ref().child('profile_images/$userId.jpg');
        await storageRef.putFile(_image!);

        // Dapatkan URL gambar yang diupload
        String downloadUrl = await storageRef.getDownloadURL();

        // Update URL gambar di Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'profileImageUrl': downloadUrl});

        setState(() {
          profileImageUrl = downloadUrl; // Update URL gambar di state
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto profil berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal memperbarui foto profil: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveChanges() async {
    String currentEmail = emailController.text;
    String currentName = nameController.text;
    String currentPhone = phoneController.text;

    DocumentSnapshot<Map<String, dynamic>> userData =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    String originalEmail = userData.data()?['email'] ?? '';
    String originalName = userData.data()?['namaLengkap'] ?? '';
    String originalPhone = userData.data()?['nomorHandphone'] ?? '';

    if (currentEmail == originalEmail &&
        currentName == originalName &&
        currentPhone == originalPhone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada perubahan pada profil'),
        backgroundColor: Colors.blueGrey,
      ));
      return;
    }

    QuerySnapshot emailCheck = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: currentEmail)
        .get();

    if (emailCheck.docs.isNotEmpty && currentEmail != originalEmail) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email sudah terdaftar'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    QuerySnapshot phoneCheck = await FirebaseFirestore.instance
        .collection('users')
        .where('nomorHandphone', isEqualTo: currentPhone)
        .get();

    if (phoneCheck.docs.isNotEmpty && currentPhone != originalPhone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nomor handphone sudah terdaftar'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      await _reauthenticateUser();

      if (user != null && user!.email != currentEmail) {
        await user!.updateEmail(currentEmail);
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'email': currentEmail,
        'namaLengkap': currentName,
        'nomorHandphone': currentPhone,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perubahan disimpan!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memperbarui profil: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // Menghilangkan fokus saat tap di luar TextField
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: const Color(0xFF6EACDA),
        ),
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF87CEEB), Color(0xFF4682B4)], // Gradien biru
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Display the selected image in the CircleAvatar
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!) // Gambar dari Firebase
                      : (_image != null
                          ? FileImage(_image!) as ImageProvider
                          : const AssetImage(
                              'assets/images/default_avatar.png')),
                ),
                const SizedBox(height: 10),

                // Button to pick image
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Gallery'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text('Camera'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                buildProfileInputField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email,
                ),

                const SizedBox(height: 20),

                buildProfileInputField(
                  controller: nameController,
                  label: "Nama",
                  icon: Icons.person,
                ),

                const SizedBox(height: 20),

                buildProfileInputField(
                  controller: phoneController,
                  label: "Nomor Handphone",
                  icon: Icons.phone,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}
