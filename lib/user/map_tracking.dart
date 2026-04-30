import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'chat_page.dart';

class MapTracking extends StatefulWidget {
  const MapTracking({super.key});

  @override
  State<MapTracking> createState() => _MapTrackingState();
}

class _MapTrackingState extends State<MapTracking> {
  GoogleMapController? mapController;

  LatLng userLocation = const LatLng(0, 0);
  LatLng providerLocation = const LatLng(0, 0);
  LatLng? lastProviderLocation;

  double distanceKm = 0;
  int etaMinutes = 0;

  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  // Distance
  void calculateDistance() {
    double distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      providerLocation.latitude,
      providerLocation.longitude,
    );

    distanceKm = distance / 1000;
    etaMinutes = ((distanceKm / 40) * 60).round();
  }

  //Route
  Future<void> getRoute() async {
    if (providerLocation.latitude == 0) return;

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "AIzaSyBnp17DvBSINdRKpQen0jq799XgV-YEDYU",
      request: PolylineRequest(
        origin: PointLatLng(
          userLocation.latitude,
          userLocation.longitude,
        ),
        destination: PointLatLng(
          providerLocation.latitude,
          providerLocation.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates =
          result.points.map((e) => LatLng(e.latitude, e.longitude)).toList();

      polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: polylineCoordinates,
          width: 6,
          color: Colors.amber,
        )
      };

      if (mounted) setState(() {});
    }
  }

  // Pay Cash
  Future<void> payCash(String requestId) async {
    await FirebaseFirestore.instance
        .collection("requests")
        .doc(requestId)
        .update({
      "paymentStatus": "paid",
      "paidAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment Successful 💰"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text("No requests found")),
          );
        }

        final docs = snapshot.data!.docs;

        docs.sort((a, b) {
          final aTime =
              (a["createdAt"] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime =
              (b["createdAt"] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        final doc = docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final requestId = doc.id;
        final status = data["status"];
        final providerName = data["providerName"] ?? "Mechanic";
        final paymentStatus = data["paymentStatus"] ?? "pending";
        final amount = data["amount"] ?? 0;

        //User location
        if (data["userLat"] != null) {
          userLocation = LatLng(data["userLat"], data["userLng"]);
        }

        //Provider location
        if (data["providerLat"] != null) {
          final newLocation = LatLng(
            data["providerLat"],
            data["providerLng"],
          );

          if (lastProviderLocation == null ||
              lastProviderLocation!.latitude != newLocation.latitude ||
              lastProviderLocation!.longitude != newLocation.longitude) {
            providerLocation = newLocation;
            lastProviderLocation = newLocation;

            calculateDistance();
            getRoute();
          }
        }

        //COMPLETED SCREEN
        if (status == "completed") {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text("Payment Summary",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          size: 80, color: Colors.green),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Service Completed",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Your request has been fulfilled by $providerName.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                          Text(
                            "₹$amount",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (paymentStatus == "pending")
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () => payCash(requestId),
                          icon: const Icon(Icons.payments_rounded),
                          label: Text("Pay ₹$amount Cash 💵",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (paymentStatus == "paid")
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.green),
                            SizedBox(width: 10),
                            Text(
                              "Payment Successful ✅",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
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

        //  Status message
        String statusMessage = "Waiting for mechanic...";
        Color statusColor = Colors.orange;
        if (status == "accepted") {
          statusMessage = "Mechanic is on the way 🚗";
          statusColor = Colors.blue;
        }
        if (status == "arrived") {
          statusMessage = "Mechanic has arrived 🛠";
          statusColor = Colors.purple;
        }

        // Markers
        Set<Marker> markers = {
          Marker(
            markerId: const MarkerId("user"),
            position: userLocation,
            infoWindow: const InfoWindow(title: "Your Location"),
          ),
          if (providerLocation.latitude != 0)
            Marker(
              markerId: const MarkerId("provider"),
              position: providerLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(title: providerName),
            ),
        };

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Track Assistance",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: userLocation,
                    zoom: 14,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        if (providerLocation.latitude != 0)
                          Text(
                            "$etaMinutes mins away",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.amber[100],
                          child: const Icon(Icons.person, color: Colors.amber),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                providerName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(statusMessage,
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(requestId: requestId),
                              ),
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.amber[50], shape: BoxShape.circle),
                            child: const Icon(Icons.chat_bubble_rounded,
                                color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                    if (providerLocation.latitude != 0) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            "Distance: ${distanceKm.toStringAsFixed(2)} km",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
