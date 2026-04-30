import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_details.dart';
import 'provider_status.dart';
import 'provider_history.dart';
import 'provider_profile.dart';

class ProviderHome extends StatelessWidget {
  const ProviderHome({super.key});

  // REJECT FUNCTION
  Future<void> rejectRequest(String requestId, BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection("requests")
          .doc(requestId)
          .update({
        "status": "pending",
        "providerId": null,
        "rejectedBy": FieldValue.arrayUnion([uid]),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request rejected "),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error rejecting request "),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    final providerId = user.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "RoadCare – Provider",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProviderProfile()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("providers")
            .doc(providerId)
            .snapshots(),
        builder: (context, providerSnapshot) {
          if (providerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          final providerData = providerSnapshot.data?.data() as Map<String, dynamic>?;
          final bool online = providerData?["online"] ?? false;

          //  OFFLINE VIEW
          if (!online) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.power_settings_new_rounded, size: 80, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "You are Offline",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Switch your status to online to start receiving service requests from nearby users.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProviderStatus()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Go Online", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ONLINE VIEW
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "You are Online",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProviderStatus()),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Change"),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Available Jobs",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              /// LIVE REQUESTS LIST
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("requests")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No active requests right now 🚗"));
                    }

                    final docs = snapshot.data!.docs;

                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data["status"];
                      final assignedProvider = data["providerId"];
                      final rejectedBy = data["rejectedBy"] ?? [];

                      if (rejectedBy.contains(providerId)) return false;

                      return status == "pending" ||
                          (status == "accepted" && assignedProvider == providerId);
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text("No jobs available", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredDocs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.car_repair_rounded, color: Colors.amber[800]),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data["service"] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text(data["note"] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JobDetails(requestId: doc.id, requestData: data),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        minimumSize: const Size(80, 35),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text("View", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 5),
                                    TextButton(
                                      onPressed: () => rejectRequest(doc.id, context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        minimumSize: const Size(80, 35),
                                      ),
                                      child: const Text("Reject", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderHistory()));
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderProfile()));
          }
        },
      ),
    );
  }
}
