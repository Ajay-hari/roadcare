import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'provider_map.dart';

class JobDetails extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const JobDetails({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  Future<void> acceptJob(BuildContext context) async {
    final providerUid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("requests").doc(requestId);

    try {
      // GET PROVIDER NAME FROM USERS COLLECTION
      final providerDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(providerUid)
          .get();

      final providerName = providerDoc.data()?["name"] ?? "Provider";

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception("Job does not exist");
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentStatus = data["status"];

        // Already accepted
        if (currentStatus != "pending") {
          throw Exception("Job already taken");
        }

        //UPDATE WITH NAME
        transaction.update(docRef, {
          "status": "accepted",
          "providerId": providerUid,
          "providerName": providerName,
          "acceptedAt": FieldValue.serverTimestamp(),
        });
      });

      if (!context.mounted) return;

      // Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderMap(requestId: requestId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job already accepted by another provider 🚫"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = requestData["status"];
    final userName = requestData["userName"] ?? "Customer";
    final service = requestData["service"] ?? "General Assistance";
    final note = requestData["note"] ?? "No additional details provided.";

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
          "Job Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_rounded, size: 60, color: Colors.amber[800]),
              ),
            ),
            const SizedBox(height: 30),
            _buildDetailSection("Service Requested", service, Icons.car_repair_rounded),
            const SizedBox(height: 20),
            _buildDetailSection("Customer Name", userName, Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildDetailSection("Problem Description", note, Icons.description_outlined),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: currentStatus == "pending" ? () => acceptJob(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  currentStatus == "pending" ? "Accept Job" : "Job Not Available",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
