import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_check.dart';

class RoleSelection extends StatefulWidget {
  const RoleSelection({super.key});

  @override
  State<RoleSelection> createState() => _RoleSelectionState();
}

class _RoleSelectionState extends State<RoleSelection> {
  final nameController = TextEditingController();
  bool loading = false;

  Future<void> selectRole(String role) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your name"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => loading = true);
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;
      final email = user.email;
      final name = nameController.text.trim();

      //Save in users collection
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": name,
        "role": role,
        "email": email,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // If provider → create provider doc
      if (role == "provider") {
        await FirebaseFirestore.instance.collection("providers").doc(uid).set({
          "name": name,
          "email": email,
          "approved": false,
          "online": false,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleCheck()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save role: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Setup Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_pin_rounded,
                  size: 100,
                  color: Colors.amber,
                ),
                const SizedBox(height: 10),
                Text(
                  "Tell us about yourself",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const Text(
                  "Choose how you want to use RoadCare",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "I am a...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : () => selectRole("user"),
                    icon: const Icon(Icons.directions_car_filled_rounded),
                    label: const Text(
                      "Service Needed (User)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : () => selectRole("provider"),
                    icon: const Icon(Icons.home_repair_service_rounded),
                    label: const Text(
                      "Service Provider (Mechanic)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.amber, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (loading) ...[
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(color: Colors.amber),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
