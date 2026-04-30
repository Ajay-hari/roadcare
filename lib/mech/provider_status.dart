import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderStatus extends StatefulWidget {
  const ProviderStatus({super.key});

  @override
  State<ProviderStatus> createState() => _ProviderStatusState();
}

class _ProviderStatusState extends State<ProviderStatus> {
  bool online = false;
  bool loading = true;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadStatus();
  }

  Future<void> loadStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection("providers")
        .doc(uid)
        .get();

    if (doc.exists) {
      online = doc.data()?["online"] ?? false;
    } else {
      await FirebaseFirestore.instance
          .collection("providers")
          .doc(uid)
          .set({
        "online": false,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> updateStatus(bool value) async {
    setState(() => online = value);

    final providerRef = FirebaseFirestore.instance.collection("providers").doc(uid);

    await providerRef.update({
      "online": value,
      "lastUpdated": FieldValue.serverTimestamp(),
    });

    // If provider goes OFFLINE → release active jobs
    if (!value) {
      final acceptedJobs = await FirebaseFirestore.instance
          .collection("requests")
          .where("providerId", isEqualTo: uid)
          .where("status", isEqualTo: "accepted")
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in acceptedJobs.docs) {
        batch.update(doc.reference, {
          "status": "pending",
          "providerId": FieldValue.delete(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You are offline. Active jobs released 🔄"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Availability Status",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: online ? Colors.green[50] : Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 80,
                  color: online ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                online ? "You are Online" : "You are Offline",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                online
                    ? "You are visible to customers and can receive service requests."
                    : "You are currently hidden from customers. Turn on to see jobs.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      online ? "GO OFFLINE" : "GO ONLINE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: online ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Switch(
                      value: online,
                      onChanged: updateStatus,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green[100],
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red[100],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
