import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: const [
              CircleAvatar(
                radius:
                    50, // Ubah ukuran CircleAvatar dengan memperbesar radius
                backgroundColor: Color(0xFFE0BBE4), // Warna latar belakang
                child: Icon(
                  Icons.person,
                  size:
                      40, // Ikon yang lebih besar agar proporsional dengan avatar
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Row(
            children: const [
              CircleAvatar(
                radius:
                    50, // Ubah ukuran CircleAvatar dengan memperbesar radius
                backgroundColor: Color(0xFFE0BBE4),
                child: Icon(
                  Icons.person,
                  size:
                      40, // Ikon yang lebih besar agar proporsional dengan avatar
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'User not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String displayName = userData['namaLengkap'] ?? 'User';
        String profileImageUrl = userData['profileImageUrl'] ??
            ''; // Ambil URL foto profil dari Firestore

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius:
                      40, // Ubah ukuran CircleAvatar dengan memperbesar radius
                  backgroundColor: Color.fromARGB(255, 255, 255, 255),
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size:
                              40, // Ikon yang lebih besar agar proporsional dengan avatar
                          color: Colors.black,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                bool shouldLogout = await _showLogoutDialog(context);
                if (shouldLogout) {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Iya'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
