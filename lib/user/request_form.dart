import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'map_tracking.dart';

class RequestForm extends StatefulWidget {
  final String service;

  const RequestForm({super.key, required this.service});

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  final noteController = TextEditingController();
  bool isLoading = false;

  Future<void> sendRequest() async {
    if (noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter problem details"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // GET USER NAME
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      final userName = userDoc.data()?["name"] ?? "User";

      //Request permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission required"),
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() => isLoading = false);
        return;
      }

      //Get GPS location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // SAVE DATA
      await FirebaseFirestore.instance.collection("requests").add({
        "userId": uid,
        "userName": userName, // ✅ NEW
        "service": widget.service,
        "note": noteController.text.trim(),
        "status": "pending",
        "userLat": position.latitude,
        "userLng": position.longitude,
        "createdAt": FieldValue.serverTimestamp(),
        "clientTime": Timestamp.now(),
      });

      if (!mounted) return;

      //Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MapTracking(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.service,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber[800]),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "You are requesting ${widget.service} assistance. Please describe the issue clearly.",
                      style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Problem Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "e.g., My car won't start, I'm stuck near the highway...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "Confirm Request",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "We will use your current GPS location to find a provider.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
