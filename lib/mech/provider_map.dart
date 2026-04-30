import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../user/chat_page.dart';

class ProviderMap extends StatefulWidget {
  final String requestId;

  const ProviderMap({super.key, required this.requestId});

  @override
  State<ProviderMap> createState() => _ProviderMapState();
}

class _ProviderMapState extends State<ProviderMap> {
  GoogleMapController? mapController;

  LatLng providerLocation = const LatLng(0, 0);
  LatLng userLocation = const LatLng(0, 0);

  double distanceKm = 0;
  int etaMinutes = 0;
  double totalAmount = 0;

  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeLocation();
  }

  //INITIALIZE
  Future<void> initializeLocation() async {
    try {
      await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      providerLocation = LatLng(position.latitude, position.longitude);

      final doc = await FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .get();

      final data = doc.data();
      if (data == null) return;

      final providerId = data["providerId"];
      final uid = FirebaseAuth.instance.currentUser!.uid;

      if (providerId != uid) {
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      await loadUserLocation();
      startLiveLocation(); 

      calculateDistance();
      await getRoute();

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //  LOAD USER
  Future<void> loadUserLocation() async {
    final doc = await FirebaseFirestore.instance
        .collection("requests")
        .doc(widget.requestId)
        .get();

    final data = doc.data();

    if (data != null && data["userLat"] != null) {
      userLocation = LatLng(data["userLat"], data["userLng"]);
    }
  }

  //  LIVE LOCATION
  void startLiveLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      if (!mounted) return;
      
      providerLocation = LatLng(position.latitude, position.longitude);

      await FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .update({
        "providerLat": position.latitude,
        "providerLng": position.longitude,
      });

      calculateDistance();
      await getRoute();

      if (mounted) setState(() {});
    });
  }

  //  DISTANCE + PRICE
  void calculateDistance() {
    double distance = Geolocator.distanceBetween(
      providerLocation.latitude,
      providerLocation.longitude,
      userLocation.latitude,
      userLocation.longitude,
    );

    distanceKm = distance / 1000;
    if (distanceKm < 1) distanceKm = 1;

    etaMinutes = ((distanceKm / 40) * 60).round();

    totalAmount = 50 + (distanceKm * 8);
  }

  //  ROUTE
  Future<void> getRoute() async {
    if (providerLocation.latitude == 0 || userLocation.latitude == 0) return;

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "AIzaSyBnp17DvBSINdRKpQen0jq799XgV-YEDYU",
      request: PolylineRequest(
        origin: PointLatLng(
          providerLocation.latitude,
          providerLocation.longitude,
        ),
        destination: PointLatLng(
          userLocation.latitude,
          userLocation.longitude,
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

  //  ARRIVED
  Future<void> markArrived() async {
    await FirebaseFirestore.instance
        .collection("requests")
        .doc(widget.requestId)
        .update({"status": "arrived"});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Marked as arrived 🛠"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  //  COMPLETE JOB
  Future<void> completeJob() async {
    await FirebaseFirestore.instance
        .collection("requests")
        .doc(widget.requestId)
        .update({
      "status": "completed",
      "completedAt": FieldValue.serverTimestamp(),
      "paymentStatus": "pending",
      "amount": totalAmount,
      "providerLat": null,
      "providerLng": null,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job completed. Waiting for payment 💵"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  //  PAYMENT SCREEN (ENHANCED)
  Widget paymentScreen(Map<String, dynamic> data) {
    final paymentStatus = data["paymentStatus"];
    final amount = data["amount"] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Job Summary",
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
                "Job Completed",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "You have successfully fulfilled the service request.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
                    const Text("Earning Amount",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    Text(
                      "₹${amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                  color: paymentStatus == "paid"
                      ? Colors.green[100]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        paymentStatus == "paid"
                            ? Icons.verified_rounded
                            : Icons.pending_rounded,
                        color: paymentStatus == "paid"
                            ? Colors.green
                            : Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      paymentStatus == "paid"
                          ? "Payment Received 💰"
                          : "Waiting for Payment...",
                      style: TextStyle(
                          fontSize: 16,
                          color: paymentStatus == "paid"
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Back to Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data["status"];
        final userName = data["userName"] ?? "Customer";
        final serviceType = data["service"] ?? "Service";

        // SHOW PAYMENT SCREEN
        if (status == "completed") {
          return paymentScreen(data);
        }

        //  NORMAL MAP
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Navigating to Job",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: providerLocation,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("provider"),
                      position: providerLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(title: "You"),
                    ),
                    Marker(
                      markerId: const MarkerId("user"),
                      position: userLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange),
                      infoWindow: InfoWindow(title: userName),
                    ),
                  },
                  polylines: polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
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
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.amber[100],
                          child: const Icon(Icons.person, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(serviceType, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoItem(Icons.directions_car_rounded,
                            "${distanceKm.toStringAsFixed(1)} km"),
                        _infoItem(
                            Icons.access_time_filled_rounded, "$etaMinutes min"),
                        _infoItem(Icons.payments_rounded,
                            "₹${totalAmount.toStringAsFixed(0)}",
                            color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: status == "accepted" ? markArrived : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status == "accepted" ? Colors.blue[50] : Colors.grey[200],
                              foregroundColor: status == "accepted" ? Colors.blue[800] : Colors.grey[500],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Arrived",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatPage(requestId: widget.requestId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_rounded,
                                color: Colors.amber),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: status == "arrived" ? completeJob : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status == "arrived" ? Colors.green[50] : Colors.grey[200],
                              foregroundColor: status == "arrived" ? Colors.green[800] : Colors.grey[500],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Complete",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _infoItem(IconData icon, String value, {Color color = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 5),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
