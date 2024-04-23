import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'package:open_route_service/open_route_service.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:flutter_project_template/shared-functions/icon_maker.dart';
import 'package:flutter_project_template/shared-functions/routes.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class DriversMap extends StatefulWidget {
  const DriversMap({super.key});

  @override
  State<DriversMap> createState() => _DriversMapState();
}

class _DriversMapState extends State<DriversMap> {
  late GoogleMapController mapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  final db = FirebaseFirestore.instance;
  bool isLoadingRoute = false;

  final List<LatLng> polyPoints = [];
  final Set<Polyline> polyLines = {};
  final Set<Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();
  Set<Marker> _markers = {};
  LatLng? _currentDustbinPosition;
  Position? userCurrentPosition;

  // Define your API key
  static const String _googleMapsApiKey =
      "AIzaSyD79hEbrrlDT2ko8JSpUrjgzIv7PjAwSTk"; // Replace with your actual API Key

  LocationPermission? _locationPermission;

  // distance and time api
  // State variables to store distance and duration
  double drivingDistance = 0.0; // Driving distance in meters
  int drivingDuration = 0; // Driving duration in seconds
  double walkingDistance = 0.0; // Walking distance in meters
  int walkingDuration = 0; // Walking duration in seconds

  // Define travel mode options
  static const String travelModeDriving = "driving";
  static const String travelModeWalking = "walking";
  static const String travelModeTransit = "transit";
  static const String travelModeBicycling = "bicycling";

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  // Function to get route points from the Google Maps Directions API
  // Future<List<LatLng>> getRoutePoints(
  //     String origin, String destination, String mode) async {
  //   final response = await http.get(
  //     Uri.parse(
  //       "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$mode&key=$_googleMapsApiKey",
  //     ),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);

  //     // Ensure the 'routes' list exists and contains at least one route
  //     if (data.containsKey('routes') && data['routes'].isNotEmpty) {
  //       final route = data['routes'][0]['overview_polyline']['points'];

  //       // Decode the polyline
  //       final decoder = PolylinePoints();
  //       List<PointLatLng> decodedPoints = decoder.decodePolyline(route);

  //       // Convert List<PointLatLng> to List<LatLng>
  //       List<LatLng> points = decodedPoints
  //           .map((point) => LatLng(point.latitude, point.longitude))
  //           .toList();
  //       return points;
  //     } else {
  //       throw Exception(
  //           "No routes found for the specified origin and destination.");
  //     }
  //   } else {
  //     throw Exception(
  //         "Failed to get directions with status code: ${response.statusCode}");
  //   }
  // }

  Future<List<List<LatLng>>> getRoutePoints(
      String origin, String destination, String mode) async {
    final response = await http.get(
      Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$mode&key=$_googleMapsApiKey",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Ensure the 'routes' list exists and contains at least one route
      if (data.containsKey('routes') && data['routes'].isNotEmpty) {
        List<List<LatLng>> allRoutes = [];

        // Iterate through each route
        for (var routeData in data['routes']) {
          final route = routeData['overview_polyline']['points'];

          // Decode the polyline
          final decoder = PolylinePoints();
          List<PointLatLng> decodedPoints = decoder.decodePolyline(route);

          // Convert List<PointLatLng> to List<LatLng>
          List<LatLng> points = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          allRoutes.add(points);
        }
        print("ALL ROUTES ${allRoutes}");
        print("NUMBER OF ROUTES ${allRoutes.length}");

        return allRoutes;
      } else {
        throw Exception(
            "No routes found for the specified origin and destination.");
      }
    } else {
      throw Exception(
          "Failed to get directions with status code: ${response.statusCode}");
    }
  }

  // Function to clear the current opened route
  void clearRoute() {
    setState(() {
      polyLines.clear();
    });
  }

  // Function to recalculate the route when the origin or destination changes
  void recalculateRoute() async {
    // Clear existing polylines
    clearRoute();

    // Recalculate the route if there's a dustbin position available
    if (_currentDustbinPosition != null) {
      await showRouteToDustbin(_currentDustbinPosition!);
    }
  }

// Function to handle camera movement events
  void onCameraMove(CameraPosition position) {
    // You can add logic here to adjust the camera based on the current polyline or markers
    // recalculateRoute();
  }


  Future<void> showRouteToDustbin(LatLng dustbinPosition) async {
    // Set isLoadingRoute to true to indicate that the route calculation process has started
    setState(() {
      isLoadingRoute = true;
    });

    try {
      // Get the user's current position
      final Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );

      // Convert the current position to a LatLng
      LatLng origin =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      // Move the camera to the user's current position
      mapController.animateCamera(CameraUpdate.newLatLng(origin));

      // Calculate the route points using the origin and destination
      final List<List<LatLng>> allRoutes = await getRoutePoints(
        "${origin.latitude},${origin.longitude}",
        "${dustbinPosition.latitude},${dustbinPosition.longitude}",
        "driving", // Specify travel mode here (e.g., "walking" or "bicycling")
      );

      // Iterate through each route and create polylines
      for (int i = 0; i < allRoutes.length; i++) {
        final List<LatLng> routePoints = allRoutes[i];

        // Create a polyline for the route
        final Polyline routePolyline = Polyline(
          polylineId: PolylineId("route_to_dustbin_$i"),
          points: routePoints,
          width: i == 0
              ? 5
              : 2, // Main route has thicker width, other routes have thinner width
          color: i == 0
              ? Colors.green
              : Colors.grey, // Main route is green, other routes are grey
          patterns:
              i == 0 ? [] : [PatternItem.dot], // Dotted line for other routes
        );

        // Update the state to add the polyline to the map
        setState(() {
          polyLines.add(routePolyline);
        });
      }

      // Subscribe to continuous location updates
      geolocator.Geolocator.getPositionStream().listen((Position newPosition) {
        // Update the user's current position
        setState(() {
          origin = LatLng(newPosition.latitude, newPosition.longitude);
        });

        // Move the camera to the updated position
        mapController.animateCamera(CameraUpdate.newLatLng(origin));
      });
    } catch (e) {
      print('Error in showRouteToDustbin: $e');
    } finally {
      // Set isLoadingRoute to false to indicate that the route calculation process is complete
      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _controllerGoogleMap.complete(controller);

    // Load markers from Firestore
    await _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/images/greendustbin.png', 90);

    await db
        .collection("data")
        .where("percentage", isLessThanOrEqualTo: 60)
        .where("state")
        .snapshots()
        .listen((event) {
      setState(() {
        _markers.clear();
        for (var doc in event.docs) {
          final position =
              LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title:
                  "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
              snippet: "percentage : ${doc.data()["percentage"]}",
              onTap: () => showRouteToDustbin(position),
            ),
            icon: BitmapDescriptor.fromBytes(markerIcon),
          );
          _markers.add(marker);
        }
      });
    });

    final Uint8List markerIconFull =
        await getBytesFromAsset('assets/images/reddustbin.png', 90);

    await db
        .collection("data")
        .where("percentage", isGreaterThan: 60)
        .snapshots()
        .listen((event) {
      setState(() {
        for (var doc in event.docs) {
          final position =
              LatLng(doc.data()["Latitude"], doc.data()["Longitude"]);
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title:
                  "id : ${doc.data()["name"]}\n state: ${doc.data()["state"]}",
              snippet: "percentage : ${doc.data()["percentage"]}",
              onTap: () => showRouteToDustbin(position),
            ),
            icon: BitmapDescriptor.fromBytes(markerIconFull),
          );
          _markers.add(marker);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // _startPositionListener();
    checkIfLocationPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true, // Disable the default my location button
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(-6.76438766, 39.22930733),
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            onCameraMove: onCameraMove,
            markers: _markers,
            polylines: polyLines,
            indoorViewEnabled: true,
          ),
          Visibility(
            visible: isLoadingRoute,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          Positioned(
            top: 100,
            left: 20,
            child: GestureDetector(
              onTap: () {
                print("Loading");
              },
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.menu,
                  color: Color.fromARGB(136, 0, 0, 0),
                ),
              ),
            ),
          ),
          // Custom "My Location" button
          Positioned(
            bottom: 20,
            // right: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () async {
                Position currentPosition = await Geolocator.getCurrentPosition(
                  desiredAccuracy: geolocator.LocationAccuracy.high,
                );
                LatLng userPosition =
                    LatLng(currentPosition.latitude, currentPosition.longitude);
                mapController.animateCamera(
                  CameraUpdate.newLatLng(userPosition),
                );
              },
              child: Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 120),
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            child: const Text("Refresh"),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DriversMap()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              textStyle: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Spacer(),
                          Visibility(
                            visible: polyLines.isNotEmpty,
                            child: ElevatedButton(
                              child: const Text("Cancel route"),
                              onPressed: clearRoute,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                textStyle: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}