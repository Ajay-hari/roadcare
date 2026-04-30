import 'package:flutter/material.dart';
import 'select_service.dart';
import 'request_history.dart';
import 'user_profile.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "RoadCare",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfile()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help you today?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildActionCard(
              context,
              title: "Request Service",
              subtitle: "Get immediate help for your vehicle",
              icon: Icons.emergency_share_rounded,
              color: Colors.amber,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectService()));
              },
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              title: "Request History",
              subtitle: "View your past service requests",
              icon: Icons.history_rounded,
              color: Colors.white,
              textColor: Colors.black87,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestHistory()));
              },
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              title: "My Profile",
              subtitle: "Manage your account and settings",
              icon: Icons.person_outline_rounded,
              color: Colors.white,
              textColor: Colors.black87,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfile()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color == Colors.white ? Colors.amber[50] : Colors.white24,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 32, color: textColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textColor.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
