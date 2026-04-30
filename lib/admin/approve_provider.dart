import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveProvider extends StatelessWidget {
  const ApproveProvider({super.key});

  // APPROVE
  Future<void> approve(String providerId) async {
    await FirebaseFirestore.instance.collection("providers").doc(providerId).update({
      "approved": true,
    });
  }

  //DELETE
  Future<void> deleteProvider(String providerId) async {
    // delete from providers
    await FirebaseFirestore.instance.collection("providers").doc(providerId).delete();

    // delete from users (important)
    await FirebaseFirestore.instance.collection("users").doc(providerId).delete();
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
          "Approve Providers",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("providers").where("approved", isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading providers"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  const Text(
                    "No pending providers",
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

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
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.amber[50],
                        child: Icon(Icons.person, color: Colors.amber[800]),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data["name"] ?? "New Provider",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              data["email"] ?? "No Email",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => approve(doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Approve", style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  title: const Text("Delete Provider?"),
                                  content: const Text("This action cannot be undone."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await deleteProvider(doc.id);
                              }
                            },
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
    );
  }
}
