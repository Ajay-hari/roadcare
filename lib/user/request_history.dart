import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestHistory extends StatelessWidget {
  const RequestHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
          "Request History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("userId", isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading history"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text(
                    "No requests yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Sort by clientTime (latest first)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTime = (aData["clientTime"] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime = (bData["clientTime"] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

            return bTime.compareTo(aTime);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final service = data["service"] ?? "";
              final status = data["status"] ?? "";
              final note = data["note"] ?? "";

              //  Get time
              final timestamp = data["clientTime"] as Timestamp?;
              String timeText = "No time";

              if (timestamp != null) {
                final date = timestamp.toDate();
                timeText = "${date.day}/${date.month}/${date.year}  "
                    "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              }

              // Status colors & icons
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.hourglass_empty_rounded;

              if (status == "completed") {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle_rounded;
              } else if (status == "accepted") {
                statusColor = Colors.blue;
                statusIcon = Icons.directions_car_rounded;
              } else if (status == "arrived") {
                statusColor = Colors.purple;
                statusIcon = Icons.location_on_rounded;
              }

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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  service,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 5),
                                Text(
                                  timeText,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
