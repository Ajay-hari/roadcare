import 'package:flutter/material.dart';

class JobCompletedScreen extends StatelessWidget {
  const JobCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.check_circle,
                color: Colors.green, size: 100),

            const SizedBox(height: 20),

            const Text(
              "Job Completed ✅",
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Go Home"),
            )

          ],
        ),
      ),
    );
  }
}