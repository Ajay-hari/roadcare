import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderHistory extends StatelessWidget {
  const ProviderHistory({super.key});

  Future<List<QueryDocumentSnapshot>> _fetchHistory() async {
    final providerId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection("requests")
        .where("providerId", isEqualTo: providerId)
        .where("status", isEqualTo: "completed")
        .get();

    final docs = snapshot.docs;

    //SAFE SORT (no crash if completedAt missing)
    docs.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)["completedAt"] as Timestamp?;
      final bTime = (b.data() as Map<String, dynamic>)["completedAt"] as Timestamp?;

      return (bTime?.millisecondsSinceEpoch ?? 0)
          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
    });

    return docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Job History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {

          //Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          //Error
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading history"),
            );
          }

          // Empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_rounded,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text(
                    "No completed jobs yet 🛠",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {

              final data = docs[index].data() as Map<String, dynamic>;

              // Time
              final timestamp = data["completedAt"] as Timestamp?;
              String timeText = "No time";

              if (timestamp != null) {
                final date = timestamp.toDate();
                timeText =
                "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }

              //  FIXED AMOUNT (SAFE)
              final amount = (data["amount"] ?? 0).toDouble();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 15),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Title + Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data["service"] ?? "Service",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "₹${amount.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Note
                            Text(
                              data["note"] ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Date
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 5),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}