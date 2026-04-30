import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'approve_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // 🔥 COUNT FUNCTION
  Future<int> getCount(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RoadCare Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Monitor platform activity and manage users",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // 🔥 STATS CARDS
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard("Users", "users", Icons.people_alt_rounded, Colors.blue),
                _buildStatCard("Providers", "providers", Icons.engineering_rounded, Colors.orange),
                _buildStatCard("Requests", "requests", Icons.assignment_rounded, Colors.green),
                _buildStatCard("Admins", "admins", Icons.admin_panel_settings_rounded, Colors.purple),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildActionTile(
              context,
              title: "Manage Providers",
              subtitle: "Approve or reject service providers",
              icon: Icons.how_to_reg_rounded,
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApproveProvider()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  // 🔥 REUSABLE STAT CARD
  Widget _buildStatCard(String title, String collection, IconData icon, Color color) {
    return FutureBuilder<int>(
      future: getCount(collection),
      builder: (context, snapshot) {
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!snapshot.hasData)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                else
                  Text(
                    snapshot.data.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
