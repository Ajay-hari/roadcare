import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection.dart';
import '../auth/login_page.dart';
import '../user/user_home.dart';
import '../mech/provider_home.dart';
import '../admin/admin_dashboard.dart';

class RoleCheck extends StatelessWidget {
  const RoleCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Safety check
    if (user == null) {
      return const RoleSelection();
    }

    final uid = user.uid;

    return FutureBuilder<Widget>(
      future: _determineScreen(uid, context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  const Text("Something went wrong"),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text("Logout"),
                  )
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const RoleSelection();
        }

        return snapshot.data!;
      },
    );
  }

  Future<Widget> _determineScreen(String uid, BuildContext context) async {
    try {
      // ADMIN
      final adminDoc = await FirebaseFirestore.instance
          .collection("admins")
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        return const AdminDashboard();
      }

      //  PROVIDER
      final providerDoc = await FirebaseFirestore.instance
          .collection("providers")
          .doc(uid)
          .get();

      if (providerDoc.exists) {
        final approved = providerDoc.data()?["approved"] ?? false;

        if (!approved) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                )
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.engineering_outlined,
                      size: 100,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Account Under Review",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your provider account is being verified by our team. We'll notify you once it's active.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    const CircularProgressIndicator(color: Colors.amber),
                  ],
                ),
              ),
            ),
          );
        }

        return const ProviderHome();
      }

      //  USER
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return const UserHome();
      }

      return const RoleSelection();
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.amber),
              const SizedBox(height: 10),
              const Text("Error loading application state"),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text("Try Logging In Again"),
              )
            ],
          ),
        ),
      );
    }
  }
}
